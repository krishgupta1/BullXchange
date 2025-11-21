import 'package:flutter/material.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_option_chain_service.dart'; // 👈 NEW IMPORT

// ⭐️ MODEL (Unchanged)
class OptionChainRow {
  final dynamic strikePrice;
  final Map<String, dynamic>? ce;
  final Map<String, dynamic>? pe;

  OptionChainRow({required this.strikePrice, this.ce, this.pe});

  factory OptionChainRow.fromMap(Map<String, dynamic> map) {
    return OptionChainRow(
      strikePrice: map['strikePrice'],
      ce: map['CE'] as Map<String, dynamic>?,
      pe: map['PE'] as Map<String, dynamic>?,
    );
  }
}

class OptionChainProvider extends ChangeNotifier {
  // ⭐️ Replace NSE Service with Angel Service
  final AngelOneOptionChainService _apiService = AngelOneOptionChainService();

  final String symbol;

  bool _isLoading = false;
  String? _error;
  List<OptionChainRow> _rows = [];
  double? _underlyingLtp;
  int? _atmIndex;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OptionChainRow> get rows => _rows;
  double? get underlyingLtp => _underlyingLtp;
  int? get atmIndex => _atmIndex;

  OptionChainProvider({required this.symbol}) {
    fetchOptionChain();
  }

  Future<void> fetchOptionChain() async {
    _isLoading = true;
    _error = null;
    _atmIndex = null;

    // Only notify if initial load
    if (_rows.isEmpty) notifyListeners();

    try {
      // ⭐️ Call the new Angel service
      final rawData = await _apiService.fetchOptionChainData(symbol);

      if (rawData == null) {
        _error = "Failed to fetch data from Angel One.";
      } else {
        // 2. Get LTP (Might be 0.0 if not fetched separately, handle gracefully)
        _underlyingLtp = (rawData['records']?['underlyingValue'] as num?)
            ?.toDouble();

        // If LTP is 0 (common when building manual chains without spot token),
        // we can try to infer it from the middle of the chain or leave it null.

        final List<dynamic>? dataList = rawData['filtered']?['data'];

        if (dataList == null || dataList.isEmpty) {
          _error = "No active contracts found for $symbol.";
          _rows = [];
        } else {
          _rows = dataList
              .map(
                (item) => OptionChainRow.fromMap(item as Map<String, dynamic>),
              )
              .toList();

          // If we didn't get a Spot LTP, we can't find ATM accurately.
          // But if we do have it (or you fetch it separately), we calculate:
          if (_underlyingLtp != null && _underlyingLtp! > 0) {
            _findAtmIndex();
          }
        }
      }
    } catch (e, st) {
      AppLog.e("💥 Error in OptionChainProvider: $e\n$st");
      _error = "Error loading Angel One data.";
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
      (row) => (row.strikePrice as num) >= _underlyingLtp!,
    );

    if (firstOtmIndex == 0) {
      _atmIndex = 0;
    } else if (firstOtmIndex > 0) {
      _atmIndex = firstOtmIndex - 1;
    } else {
      _atmIndex = _rows.length - 1;
    }
  }
}
