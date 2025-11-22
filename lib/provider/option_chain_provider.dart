import 'package:flutter/foundation.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_option_chain_service.dart';
import 'package:bullxchange/models/market_overview_data.dart'; // Import the new model

class OptionChainRow {
  final double strikePrice;
  final Map<String, dynamic>? ce;
  final Map<String, dynamic>? pe;

  OptionChainRow({required this.strikePrice, this.ce, this.pe});

  factory OptionChainRow.fromMap(Map<String, dynamic> map) {
    return OptionChainRow(
      strikePrice: double.tryParse(map['strikePrice'].toString()) ?? 0.0,
      ce: map['CE'] as Map<String, dynamic>?,
      pe: map['PE'] as Map<String, dynamic>?,
    );
  }
}

class OptionChainProvider extends ChangeNotifier {
  final AngelOneOptionChainService _apiService = AngelOneOptionChainService();

  final String symbol;
  bool _isLoading = false;

  // ⭐️ NEW: Overview Loading State
  bool _isOverviewLoading = false;

  String? _error;
  List<OptionChainRow> _rows = [];
  double? _underlyingLtp;
  int? _atmIndex;

  // ⭐️ NEW: Hold the Overview Data
  MarketOverviewData? _overviewData;

  bool get isLoading => _isLoading;
  bool get isOverviewLoading => _isOverviewLoading; // Expose this
  String? get error => _error;
  List<OptionChainRow> get rows => _rows;
  double? get underlyingLtp => _underlyingLtp;
  int? get atmIndex => _atmIndex;
  MarketOverviewData? get overviewData => _overviewData; // Expose this

  OptionChainProvider({required this.symbol}) {
    // Fetch both when initialized
    fetchOptionChain();
    fetchMarketOverview();
  }

  // ⭐️ NEW: Fetch Market Overview Logic
  Future<void> fetchMarketOverview() async {
    _isOverviewLoading = true;
    // Don't clear old data immediately so UI doesn't flicker
    notifyListeners();

    try {
      final isBse = symbol == 'BANKEX' || symbol == 'SENSEX';
      final exchange = isBse ? 'BSE' : 'NSE';

      AppLog.i("📡 Provider: Fetching Overview for $symbol [$exchange]");

      final dataMap = await _apiService.fetchMarketOverview(
        symbol,
        exchange: exchange,
      );

      if (dataMap.isNotEmpty) {
        _overviewData = MarketOverviewData.fromMap(dataMap);

        // Optional: specific update for LTP if the main chain call failed
        if (_underlyingLtp == null || _underlyingLtp == 0) {
          _underlyingLtp = _overviewData?.currentPrice;
        }
      }
    } catch (e) {
      AppLog.e("💥 Overview Fetch Error: $e");
    } finally {
      _isOverviewLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOptionChain() async {
    _isLoading = true;
    _error = null;
    _atmIndex = null;

    if (_rows.isEmpty) notifyListeners();

    try {
      final isBse = symbol == 'BANKEX' || symbol == 'SENSEX';
      final exchange = isBse ? 'BSE' : 'NSE';

      AppLog.i("📡 Provider: Fetching Option Chain for $symbol [$exchange]");

      final rawData = await _apiService.fetchOptionChainData(
        symbol,
        exchange: exchange,
      );

      // Extract LTP from chain response
      if (rawData['records'] != null &&
          rawData['records']['underlyingValue'] != null) {
        _underlyingLtp = double.tryParse(
          rawData['records']['underlyingValue'].toString(),
        );
      }

      final List<dynamic>? dataList = rawData['filtered']?['data'];

      if (dataList == null || dataList.isEmpty) {
        _error = "No active contracts found for $symbol ($exchange).";
        _rows = [];
      } else {
        _rows = dataList.map((item) => OptionChainRow.fromMap(item)).toList();
        if (_underlyingLtp != null && _underlyingLtp! > 0) {
          _findAtmIndex();
        }
      }
    } catch (e, st) {
      AppLog.e("💥 Provider Error: $e\n$st");
      _error = "An unexpected error occurred.";
      _rows = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _findAtmIndex() {
    if (_underlyingLtp == null || _rows.isEmpty) {
      _atmIndex = null;
      return;
    }

    int firstOtmIndex = _rows.indexWhere(
      (row) => row.strikePrice >= _underlyingLtp!,
    );

    if (firstOtmIndex == -1) {
      _atmIndex = _rows.length - 1;
    } else if (firstOtmIndex == 0) {
      _atmIndex = 0;
    } else {
      _atmIndex = firstOtmIndex - 1;
    }
  }
}
