import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/nse_api_service.dart';
import 'package:bullxchange/utils/logger.dart';

class OptionChainRow {
  final num strikePrice;
  final Map<String, dynamic>? ce;
  final Map<String, dynamic>? pe;

  OptionChainRow({
    required this.strikePrice,
    this.ce,
    this.pe,
  });

  factory OptionChainRow.fromJson(Map<String, dynamic> json) {
    return OptionChainRow(
      strikePrice: num.tryParse(json['strikePrice']?.toString() ?? '') ?? 0,
      ce: json['CE'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['CE'])
          : null,
      pe: json['PE'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['PE'])
          : null,
    );
  }
}

class OptionChainProvider with ChangeNotifier {
  final NseApiService _apiService = NseApiService();
  final String symbol; // e.g., NIFTY or BANKNIFTY

  bool isLoading = false;
  String? error;
  List<OptionChainRow> rows = [];

  Timer? _timer;

  OptionChainProvider({
    required this.symbol,
  }) {
    _init();
  }

  void _init() {
    fetchOptionChain();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => fetchOptionChain());
  }

  Future<void> fetchOptionChain() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final data = await _apiService.fetchOptionChain(symbol);
    if (data == null) {
      error = "Failed to load Option Chain.";
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final records = data['records'];
      if (records is Map && records['data'] is List) {
        final rawList = List<Map<String, dynamic>>.from(records['data']);
        rows = rawList.map((e) => OptionChainRow.fromJson(e)).toList();
        rows.sort((a, b) => a.strikePrice.compareTo(b.strikePrice));
      } else {
        error = "Unexpected NSE Option Chain structure.";
      }
    } catch (e, st) {
      error = "Parsing error: $e";
      AppLog.e("⚠️ NSE parse error: $e\n$st");
      rows = [];
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
