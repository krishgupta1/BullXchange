// lib/models/watchlist_item_model.dart

class WatchlistItemModel {
  final String stockSymbol;
  final String stockName;
  final String exchange;

  WatchlistItemModel({
    required this.stockSymbol,
    required this.stockName,
    required this.exchange,
  });

  Map<String, dynamic> toJson() => {
    'stockSymbol': stockSymbol,
    'stockName': stockName,
    'exchange': exchange,
  };

  factory WatchlistItemModel.fromJson(Map<String, dynamic> json) {
    return WatchlistItemModel(
      stockSymbol: json['stockSymbol'] as String,
      stockName: json['stockName'] as String,
      exchange: json['exchange'] as String,
    );
  }
}
