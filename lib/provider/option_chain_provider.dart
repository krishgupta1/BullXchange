import 'package:bullxchange/api/nse_api_service.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/utils/logger.dart'; // Your Logger

// ⭐️ STEP 1: DEFINE THE MODEL
// (This class is unchanged)
class OptionChainRow {
  final dynamic strikePrice;
  final Map<String, dynamic>? ce; // 'ce' (lowercase) for your UI
  final Map<String, dynamic>? pe; // 'pe' (lowercase) for your UI

  OptionChainRow({required this.strikePrice, this.ce, this.pe});

  /// This "factory" constructor is the translator.
  factory OptionChainRow.fromMap(Map<String, dynamic> map) {
    return OptionChainRow(
      strikePrice: map['strikePrice'],
      ce: map['CE'] as Map<String, dynamic>?,
      pe: map['PE'] as Map<String, dynamic>?,
    );
  }
}

// -----------------------------------------------------------------

// ⭐️ STEP 2: CREATE THE PROVIDER
class OptionChainProvider extends ChangeNotifier {
  final NseApiService _apiService = NseApiService();
  final String symbol;

  // --- State Variables ---
  bool _isLoading = false;
  String? _error;
  List<OptionChainRow> _rows = [];
  double? _underlyingLtp; // ⭐️ To store the LTP
  int? _atmIndex; // ⭐️ To store the index of the ATM strike

  // --- Getters for the UI ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OptionChainRow> get rows => _rows;
  double? get underlyingLtp => _underlyingLtp; // ⭐️ Getter for LTP
  int? get atmIndex => _atmIndex; // ⭐️ Getter for ATM index

  OptionChainProvider({required this.symbol}) {
    fetchOptionChain(); // Automatically fetch data when the provider is created
  }

  /// Fetches and parses the option chain data
  Future<void> fetchOptionChain() async {
    _isLoading = true;
    _error = null;
    _atmIndex = null; // Reset on fetch

    if (_rows.isEmpty) {
      notifyListeners();
    }

    try {
      // 1. Call your API Service
      final rawData = await _apiService.fetchOptionChain(symbol);

      if (rawData == null) {
        _error = "Failed to fetch data. API returned null.";
      } else {
        // ⭐️ 2. Get the LTP
        // The underlying value is in 'records'
        _underlyingLtp = (rawData['records']?['underlyingValue'] as num?)
            ?.toDouble();

        // 3. Get the list of data
        final List<dynamic>? dataList = rawData['filtered']?['data'];

        if (dataList == null || dataList.isEmpty) {
          _error = "No option chain data found for $symbol.";
          _rows = [];
        } else {
          // 4. Transform the raw data
          _rows = dataList
              .map(
                (item) => OptionChainRow.fromMap(item as Map<String, dynamic>),
              )
              .toList();
          AppLog.i(
            "✅ Successfully parsed ${_rows.length} LIVE option chain rows.",
          );

          // ⭐️ 5. Find the ATM (At-The-Money) Index
          _findAtmIndex();
        }
      }
    } catch (e, st) {
      AppLog.e("💥 Error in OptionChainProvider: $e\n$st");
      _error = "An unexpected error occurred. Please try again.";
      _rows = []; // Clear data on error
    } finally {
      _isLoading = false;
      notifyListeners(); // Tell the UI to rebuild with the new data (or error)
    }
  }

  /// ⭐️ Helper function to find the index of the strike
  /// just below the underlying LTP.
  void _findAtmIndex() {
    if (_underlyingLtp == null || _rows.isEmpty) {
      _atmIndex = null;
      return;
    }

    // Find the index of the first strike price GREATER than or EQUAL to the LTP
    int firstOtmIndex = _rows.indexWhere(
      (row) => (row.strikePrice as num) >= _underlyingLtp!,
    );

    if (firstOtmIndex == 0) {
      // If the first strike is already >= LTP, highlight it
      _atmIndex = 0;
    } else if (firstOtmIndex > 0) {
      // This is the "Out of the Money" (OTM) strike.
      // We want to highlight the one just BEFORE it (the ATM strike).
      _atmIndex = firstOtmIndex - 1;
    } else {
      // This means all strikes are < LTP (e.g., deep in the money)
      // Highlight the last one
      _atmIndex = _rows.length - 1;
    }
  }
}
