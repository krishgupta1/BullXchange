// lib/models/instrument_model.dart

class Instrument {
  final String token;
  final String symbol;
  final String name;
  final String exchSeg;

  // --- 🔽 ADD THIS LINE 🔽 ---
  final String instrumentType; // e.g., 'EQUITY', 'INDICES'

  // --- (Your existing fields) ---
  final double outstandingShares;
  final int avgVolume;

  Map<String, dynamic> liveData = {};
  List<double> chartData = []; // Add this field for actual chart data

  Instrument({
    required this.token,
    required this.symbol,
    required this.name,
    required this.exchSeg,
    required this.instrumentType,
    required this.outstandingShares,
    required this.avgVolume,
    this.chartData = const [], // Initialize with empty list
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    // Parse chart data from API response
    List<double> chartPoints = [];
    if (json['chartData'] != null) {
      chartPoints = (json['chartData'] as List)
          .map((point) => (point as num).toDouble())
          .toList();
    }

    return Instrument(
      token: json['token'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchSeg: json['exch_seg'] ?? '',
      instrumentType: json['instrumenttype'] ?? '',
      outstandingShares: (json['outstandingShares'] as num?)?.toDouble() ?? 0.0,
      avgVolume: (json['avgVolume'] as num?)?.toInt() ?? 0,
      chartData: chartPoints, // Use actual chart data from API
    );
  }
}
