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

  Instrument({
    required this.token,
    required this.symbol,
    required this.name,
    required this.exchSeg,

    // --- 🔽 ADD THIS LINE 🔽 ---
    required this.instrumentType,

    // --- (Your existing fields) ---
    required this.outstandingShares,
    required this.avgVolume,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      token: json['token'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchSeg: json['exch_seg'] ?? '',

      // --- 🔽 ADD THIS LINE 🔽 ---
      // ⚠️ Check your JSON! Is the key 'instrumenttype' or 'instrument_type'?
      instrumentType: json['instrumenttype'] ?? '',

      // --- (Your existing fields) ---
      outstandingShares: (json['outstandingShares'] as num?)?.toDouble() ?? 0.0,
      avgVolume: (json['avgVolume'] as num?)?.toInt() ?? 0,
    );
  }
}
