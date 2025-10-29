// lib/models/stock_holding_model.dart

/// This model represents a single, detailed stock purchase transaction (Record Appending).
class StockHoldingModel {
  final String stockName;
  final String stockSymbol; // SYMBOL
  final int quantity; // QUNTATITY (Transaction Quantity)
  final double transactionPrice; // BUYING PRICE
  
  // --- Detailed Transaction Fields ---
  final DateTime buyingTime; // CURR BUYING TIME
  final double charges; // CHARGES
  final double totalAmount; // TOTAL AMOUNT
  final String exchange; // NSE OR BSE
  final String transactionType; // INTRADAY OR DELIVERY

  StockHoldingModel({
    required this.stockName,
    required this.stockSymbol,
    required this.quantity,
    required this.transactionPrice,
    required this.buyingTime,
    required this.charges,
    required this.totalAmount,
    required this.exchange,
    required this.transactionType,
  });

  Map<String, dynamic> toJson() => {
        'stockName': stockName,
        'stockSymbol': stockSymbol,
        'quantity': quantity,
        'transactionPrice': transactionPrice, 
        'buyingTime': buyingTime.toIso8601String(),
        'charges': charges,
        'totalAmount': totalAmount,
        'exchange': exchange,
        'transactionType': transactionType,
      };

  factory StockHoldingModel.fromJson(Map<String, dynamic> json) {
    return StockHoldingModel(
      stockName: json['stockName'] as String,
      stockSymbol: json['stockSymbol'] as String,
      quantity: json['quantity'] as int,
      transactionPrice: (json['transactionPrice'] as num).toDouble(),
      buyingTime: DateTime.parse(json['buyingTime'] as String),
      charges: (json['charges'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      exchange: json['exchange'] as String,
      transactionType: json['transactionType'] as String,
    );
  }
}
