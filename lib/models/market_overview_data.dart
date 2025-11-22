class MarketOverviewData {
  final double currentPrice;
  final double priceChange;
  final double percentChange;
  final double dayLow;
  final double dayHigh;
  final double yearLow;
  final double yearHigh;
  final double open;
  final double prevClose;

  MarketOverviewData({
    this.currentPrice = 0.0,
    this.priceChange = 0.0,
    this.percentChange = 0.0,
    this.dayLow = 0.0,
    this.dayHigh = 0.0,
    this.yearLow = 0.0,
    this.yearHigh = 0.0,
    this.open = 0.0,
    this.prevClose = 0.0,
  });

  // ⭐️ This is the method the Provider is looking for
  factory MarketOverviewData.fromMap(Map<String, dynamic> json) {
    return MarketOverviewData(
      currentPrice: double.tryParse(json['ltp']?.toString() ?? "0") ?? 0.0,
      priceChange:
          double.tryParse(
            json['change']?.toString() ?? json['netChange']?.toString() ?? "0",
          ) ??
          0.0,
      percentChange:
          double.tryParse(
            json['percentChange']?.toString() ??
                json['pChange']?.toString() ??
                "0",
          ) ??
          0.0,
      dayLow: double.tryParse(json['low']?.toString() ?? "0") ?? 0.0,
      dayHigh: double.tryParse(json['high']?.toString() ?? "0") ?? 0.0,
      yearLow:
          double.tryParse(
            json['52WeekLow']?.toString() ?? json['yearLow']?.toString() ?? "0",
          ) ??
          0.0,
      yearHigh:
          double.tryParse(
            json['52WeekHigh']?.toString() ??
                json['yearHigh']?.toString() ??
                "0",
          ) ??
          0.0,
      open: double.tryParse(json['open']?.toString() ?? "0") ?? 0.0,
      prevClose:
          double.tryParse(
            json['close']?.toString() ?? json['prevClose']?.toString() ?? "0",
          ) ??
          0.0,
    );
  }

  // Optional: Alias 'fromJson' to 'fromMap' if you use it elsewhere
  factory MarketOverviewData.fromJson(Map<String, dynamic> json) =>
      MarketOverviewData.fromMap(json);
}
