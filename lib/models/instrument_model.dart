class Instrument {
  final String token;
  final String symbol;
  final String name;
  final String exchSeg;

  // --- ADD THESE TWO LINES ---
  final double outstandingShares; // e.g., 6766000000 for Reliance
  final int avgVolume; // e.g., 5500000 for Reliance's 30-day avg

  Map<String, dynamic> liveData = {};

  Instrument({
    required this.token,
    required this.symbol,
    required this.name,
    required this.exchSeg,

    // --- ADD THESE TO THE CONSTRUCTOR ---
    required this.outstandingShares,
    required this.avgVolume,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      token: json['token'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchSeg: json['exch_seg'] ?? '',

      // --- ADD DEFAULTS OR VALUES FROM YOUR JSON DATA SOURCE ---
      // Make sure your JSON data file includes these values for each stock.
      outstandingShares: (json['outstandingShares'] as num?)?.toDouble() ?? 0.0,
      avgVolume: (json['avgVolume'] as num?)?.toInt() ?? 0,
    );
  }
}
