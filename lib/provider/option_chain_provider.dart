import 'package:flutter/foundation.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_option_chain_service.dart';
import 'package:bullxchange/models/market_overview_data.dart';

// ---------------------------------------------------------------------------
// ⭐️ 1. MODEL (Simplified to match your actual data)
// ---------------------------------------------------------------------------
class OptionChainRow {
  final double strikePrice;
  final String expiryDate; // Might be empty if API doesn't send it in row
  final Map<String, dynamic>? ce;
  final Map<String, dynamic>? pe;

  OptionChainRow({
    required this.strikePrice,
    required this.expiryDate,
    this.ce,
    this.pe,
  });

  factory OptionChainRow.fromMap(
    Map<String, dynamic> map, {
    String defaultExpiry = "",
  }) {
    // Try to find expiry in the row, otherwise use the default passed from Provider
    String exp =
        map['expiryDate']?.toString() ??
        map['expiry']?.toString() ??
        defaultExpiry;

    return OptionChainRow(
      strikePrice: double.tryParse(map['strikePrice'].toString()) ?? 0.0,
      expiryDate: exp,
      ce: _normalize(map['CE'] as Map<String, dynamic>?),
      pe: _normalize(map['PE'] as Map<String, dynamic>?),
    );
  }

  static Map<String, dynamic>? _normalize(Map<String, dynamic>? input) {
    if (input == null) return null;
    double getD(String key) =>
        double.tryParse(input[key]?.toString() ?? "0") ?? 0.0;
    return {
      ...input,
      'lastPrice': getD('lastPrice') == 0 ? getD('ltp') : getD('lastPrice'),
      'openInterest': getD('openInterest') == 0
          ? (getD('opnInterest') == 0 ? getD('oi') : getD('opnInterest'))
          : getD('openInterest'),
      'pChange': getD('pChange') == 0
          ? (getD('percentChange') == 0
                ? getD('netChange')
                : getD('percentChange'))
          : getD('pChange'),
      'lotSize': input['lotSize']?.toString() ?? "1",
    };
  }
}

// ---------------------------------------------------------------------------
// ⭐️ 2. PROVIDER
// ---------------------------------------------------------------------------
class OptionChainProvider extends ChangeNotifier {
  final AngelOneOptionChainService _apiService = AngelOneOptionChainService();
  final String symbol;

  bool _isLoading = false;
  bool _isOverviewLoading = false;
  bool _isDisposed = false;

  String? _error;
  List<OptionChainRow> _allRows = [];
  List<OptionChainRow> _filteredRows = [];
  List<String> _expiryDates = [];
  String _selectedExpiry = "";

  double? _underlyingLtp;
  int? _atmIndex;
  MarketOverviewData? _overviewData;

  bool get isLoading => _isLoading;
  bool get isOverviewLoading => _isOverviewLoading;
  String? get error => _error;
  List<OptionChainRow> get rows => _filteredRows;
  double? get underlyingLtp => _underlyingLtp;
  int? get atmIndex => _atmIndex;
  MarketOverviewData? get overviewData => _overviewData;
  List<String> get expiryDates => _expiryDates;
  String get selectedExpiry => _selectedExpiry;

  OptionChainProvider({required this.symbol}) {
    fetchOptionChain();
    fetchMarketOverview();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  void selectExpiry(String expiry) {
    if (_selectedExpiry == expiry) return;
    _selectedExpiry = expiry;
    _filterRows();
    _safeNotifyListeners();
  }

  Future<void> fetchMarketOverview() async {
    if (_isDisposed) return;
    _isOverviewLoading = true;
    _safeNotifyListeners();
    try {
      final exchange = (symbol == 'BANKEX' || symbol == 'SENSEX')
          ? 'BSE'
          : 'NSE';
      final data = await _apiService.fetchMarketOverview(
        symbol,
        exchange: exchange,
      );
      if (!_isDisposed && data.isNotEmpty) {
        _overviewData = MarketOverviewData.fromMap(data);
        _underlyingLtp ??= _overviewData?.currentPrice;
      }
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isOverviewLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> fetchOptionChain() async {
    if (_isDisposed) return;
    _isLoading = true;
    _error = null;
    if (_allRows.isEmpty) _safeNotifyListeners();

    try {
      final exchange = (symbol == 'BANKEX' || symbol == 'SENSEX')
          ? 'BSE'
          : 'NSE';
      final raw = await _apiService.fetchOptionChainData(
        symbol,
        exchange: exchange,
      );

      if (_isDisposed) return;

      // ⭐️ DEBUGGING: Print keys inside 'records' to find the Expiry list
      if (raw['records'] != null) {
        print("🔥 DEBUG RECORDS KEYS: ${raw['records'].keys.toList()}");
      } else {
        print("🔥 DEBUG: 'records' key is MISSING in response");
      }

      // 1. LTP Extraction
      if (raw['records']?['underlyingValue'] != null) {
        _underlyingLtp = double.tryParse(
          raw['records']['underlyingValue'].toString(),
        );
      }
      _underlyingLtp ??= 0.0;

      // 2. EXPIRY EXTRACTION
      List<String> foundExpiries = [];

      // Try finding 'expiryDates' in records (Standard NSE format)
      if (raw['records'] != null && raw['records']['expiryDates'] != null) {
        foundExpiries = List<String>.from(raw['records']['expiryDates']);
      }
      // Try finding 'expiryDates' at root
      else if (raw['expiryDates'] != null) {
        foundExpiries = List<String>.from(raw['expiryDates']);
      }

      print("🔥 DEBUG: Expiries Found: $foundExpiries");

      _expiryDates = foundExpiries;

      // If found, select first. If not, fallback to "Current"
      if (_expiryDates.isNotEmpty) {
        if (_selectedExpiry.isEmpty || _selectedExpiry == "Current") {
          _selectedExpiry = _expiryDates.first;
        }
      } else {
        _expiryDates = ["Current"];
        _selectedExpiry = "Current";
      }

      // 3. ROW PARSING
      final List<dynamic>? list = raw['filtered']?['data'];
      if (list == null || list.isEmpty) {
        if (_allRows.isEmpty) _error = "No contracts found.";
      } else {
        // Pass the selected expiry to the row since the row data doesn't have it
        _allRows = list
            .map(
              (e) => OptionChainRow.fromMap(e, defaultExpiry: _selectedExpiry),
            )
            .toList();
        _filterRows();
      }
    } catch (e) {
      if (_allRows.isEmpty) {
        _error = "Error loading data. Market might be closed.";
        print("🔥 DEBUG ERROR: $e");
        AppLog.e("Provider Error: $e");
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  void _filterRows() {
    // Since your API rows don't have dates, we assume the data returned IS for the selected expiry
    // so we just show everything.
    // If your API returns mixed data without dates in rows, sorting is impossible on client side.

    // Simple filter: Just pass through everything if date match isn't possible
    _filteredRows = _allRows;
    _findAtm();
  }

  void _findAtm() {
    if (_filteredRows.isEmpty) {
      _atmIndex = null;
      return;
    }
    if (_underlyingLtp == null || _underlyingLtp == 0) {
      _atmIndex = (_filteredRows.length / 2).floor();
      return;
    }

    int idx = _filteredRows.indexWhere((r) => r.strikePrice >= _underlyingLtp!);
    if (idx == -1) {
      _atmIndex = _filteredRows.length - 1;
    } else if (idx == 0) {
      _atmIndex = 0;
    } else {
      _atmIndex = idx - 1;
    }
  }
}
