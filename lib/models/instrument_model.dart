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
}