class Instrument {
  final String token;
  final String symbol;
  final String name;
  final String exchSeg;
  final String instrumentType;

  // ⭐️ NEW FIELDS FOR OPTIONS (Required for Option Chain)
  final String expiry;
  final String strike;
  final String lotSize;

  // Existing fields for Equity/Details
  final double outstandingShares;
  final int avgVolume;

  // Mutable state for live data
  Map<String, dynamic> liveData = {};
  List<double> chartData = [];

  Instrument({
    required this.token,
    required this.symbol,
    required this.name,
    required this.exchSeg,
    required this.instrumentType,
    required this.expiry,
    required this.strike,
    required this.lotSize,
    required this.outstandingShares,
    required this.avgVolume,
    this.chartData = const [],
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    // Parse chart data if present
    List<double> chartPoints = [];
    if (json['chartData'] != null) {
      chartPoints = (json['chartData'] as List)
          .map((point) => (point as num).toDouble())
          .toList();
    }

    return Instrument(
      token: json['token']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      exchSeg: json['exch_seg']?.toString() ?? '',
      instrumentType: json['instrumenttype']?.toString() ?? '',

      // ⭐️ OPTION FIELDS (Handle nulls for Stocks that don't have these)
      expiry: json['expiry']?.toString() ?? '',
      strike: json['strike']?.toString() ?? '0',
      lotSize: json['lotsize']?.toString() ?? '0',

      // Equity Fields
      outstandingShares: (json['outstandingShares'] as num?)?.toDouble() ?? 0.0,
      avgVolume: (json['avgVolume'] as num?)?.toInt() ?? 0,

      chartData: chartPoints,
    );
  }

  // Helper to check if it is an option
  bool get isOption => instrumentType == 'OPTIDX' || instrumentType == 'OPTSTK';
}
