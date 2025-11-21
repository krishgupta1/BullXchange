import 'package:flutter/material.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_option_chain_service.dart';

// ---------------------------------------------------------------------------
// 📦 MODEL: OptionChainRow
// (You can move this to a separate file in /models if you prefer)
// ---------------------------------------------------------------------------
class OptionChainRow {
  final double strikePrice;
  final Map<String, dynamic>? ce;
  final Map<String, dynamic>? pe;

  OptionChainRow({required this.strikePrice, this.ce, this.pe});

  factory OptionChainRow.fromMap(Map<String, dynamic> map) {
    return OptionChainRow(
      // Ensure strikePrice is double even if API sends int/string
      strikePrice: double.tryParse(map['strikePrice'].toString()) ?? 0.0,
      ce: map['CE'] as Map<String, dynamic>?,
      pe: map['PE'] as Map<String, dynamic>?,
    );
  }
}

// ---------------------------------------------------------------------------
// 🧠 PROVIDER: OptionChainProvider
// ---------------------------------------------------------------------------
class OptionChainProvider extends ChangeNotifier {
  // Service Instance
  final AngelOneOptionChainService _apiService = AngelOneOptionChainService();

  // State Variables
  final String symbol;
  bool _isLoading = false;
  String? _error;
  List<OptionChainRow> _rows = [];
  double? _underlyingLtp;
  int? _atmIndex;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OptionChainRow> get rows => _rows;
  double? get underlyingLtp => _underlyingLtp;
  int? get atmIndex => _atmIndex;

  // Constructor
  OptionChainProvider({required this.symbol}) {
    // Automatically fetch data when provider is created
    fetchOptionChain();
  }

  /// 🔄 Fetches the Option Chain Data
  Future<void> fetchOptionChain() async {
    _isLoading = true;
    _error = null;
    _atmIndex = null;

    // Notify immediately so UI shows loading spinner if it's the first load
    if (_rows.isEmpty) notifyListeners();

    try {
      AppLog.i("📡 Provider: Requesting Option Chain for $symbol");

      final rawData = await _apiService.fetchOptionChainData(symbol);

      if (rawData == null) {
        // Service returns null if API fails or logic errors (handled in service logs)
        _error = "Unable to load Option Chain.\nPlease check connection.";
      } else {
        // 1. Extract Spot Price (Underlying Value)
        // The service ensures this is calculated before returning
        if (rawData['records'] != null &&
            rawData['records']['underlyingValue'] != null) {
          _underlyingLtp = double.tryParse(
            rawData['records']['underlyingValue'].toString(),
          );
        }

        // 2. Extract List of Data Rows
        final List<dynamic>? dataList = rawData['filtered']?['data'];

        if (dataList == null || dataList.isEmpty) {
          _error = "No active contracts found for $symbol.";
          _rows = [];
        } else {
          // 3. Convert JSON List to Model List
          _rows = dataList.map((item) {
            return OptionChainRow.fromMap(item as Map<String, dynamic>);
          }).toList();

          AppLog.i("✅ Provider: Loaded ${_rows.length} strikes.");

          // 4. Calculate ATM Index for UI Highlighting
          if (_underlyingLtp != null && _underlyingLtp! > 0) {
            _findAtmIndex();
          }
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

  /// 📍 Calculates the At-The-Money (ATM) index based on Spot Price
  void _findAtmIndex() {
    if (_underlyingLtp == null || _rows.isEmpty) {
      _atmIndex = null;
      return;
    }

    // Find the first strike that is GREATER than the Spot Price
    int firstOtmIndex = _rows.indexWhere(
      (row) => row.strikePrice >= _underlyingLtp!,
    );

    if (firstOtmIndex == -1) {
      // Spot price is higher than all strikes (Deep ITM)
      _atmIndex = _rows.length - 1;
    } else if (firstOtmIndex == 0) {
      // Spot price is lower than all strikes
      _atmIndex = 0;
    } else {
      // Standard case: ATM is the strike immediately BEFORE the one that crossed the price
      // Example: Spot 19540. Strikes: 19500, 19550.
      // 19550 >= 19540 is True (Index X). ATM is Index X-1 (19500).
      _atmIndex = firstOtmIndex - 1;
    }
  }
}
