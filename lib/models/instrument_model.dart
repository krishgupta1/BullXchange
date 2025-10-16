// lib/models/instrument_model.dart

class Instrument {
  final String token;
  final String symbol;
  final String name;
  final String exchSeg;

  Map<String, dynamic> liveData = {};

  Instrument({
    required this.token,
    required this.symbol,
    required this.name,
    required this.exchSeg,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      token: json['token'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchSeg: json['exch_seg'] ?? '',
    );
  }

  // Ensure these getters handle various types (num or String)
  double get lastPrices {
    final value = liveData['ltp'] ?? liveData['lastPrices'] ?? 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double get changePercent {
    final value = liveData['percentChange'] ?? liveData['change_per'] ?? 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double get closePrice => lastPrices;
}
