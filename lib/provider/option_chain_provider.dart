import 'package:flutter/foundation.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_option_chain_service.dart';

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

    if (_rows.isEmpty) notifyListeners();

    try {
      // ⭐️ FIX: Determine Exchange based on Symbol
      final isBse = symbol == 'BANKEX' || symbol == 'SENSEX';
      final exchange = isBse ? 'BSE' : 'NSE';

      AppLog.i("📡 Provider: Fetching $symbol [$exchange]");

      // ⚠️ NOTE: I added 'exchange' here.
      // If your Service file doesn't accept this argument yet, we will fix it in the next step.
      final rawData = await _apiService.fetchOptionChainData(
        symbol,
        exchange: exchange,
      );

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
