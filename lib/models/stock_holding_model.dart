// lib/models/stock_holding_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StockHoldingModel {
  final String stockName;
  final String stockSymbol;
  final int quantity;
  final double transactionPrice;
  final DateTime buyingTime;
  final double charges;
  final double totalAmount;
  final String exchange;
  final String transactionType;

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

  StockHoldingModel copyWith({
    String? stockName,
    String? stockSymbol,
    int? quantity,
    double? transactionPrice,
    DateTime? buyingTime,
    double? charges,
    double? totalAmount,
    String? exchange,
    String? transactionType,
  }) {
    return StockHoldingModel(
      stockName: stockName ?? this.stockName,
      stockSymbol: stockSymbol ?? this.stockSymbol,
      quantity: quantity ?? this.quantity,
      transactionPrice: transactionPrice ?? this.transactionPrice,
      buyingTime: buyingTime ?? this.buyingTime,
      charges: charges ?? this.charges,
      totalAmount: totalAmount ?? this.totalAmount,
      exchange: exchange ?? this.exchange,
      transactionType: transactionType ?? this.transactionType,
    );
  }

  Map<String, dynamic> toJson() => {
    'stockName': stockName,
    'stockSymbol': stockSymbol,
    'quantity': quantity,
    'transactionPrice': transactionPrice,
    'buyingTime': Timestamp.fromDate(buyingTime), // Correctly saves new data
    'charges': charges,
    'totalAmount': totalAmount,
    'exchange': exchange,
    'transactionType': transactionType,
  };

  // --- THIS FACTORY IS THE FIX ---
  factory StockHoldingModel.fromJson(Map<String, dynamic> json) {
    // This function now safely handles both old and new date formats.
    DateTime parseBuyingTime(dynamic timeData) {
      if (timeData is Timestamp) {
        // New format: Read the Timestamp
        return timeData.toDate();
      } else if (timeData is String) {
        // Old format: Parse the String
        return DateTime.parse(timeData);
      } else {
        // Fallback if data is missing or invalid
        return DateTime.now();
      }
    }

    return StockHoldingModel(
      stockName: json['stockName'] as String,
      stockSymbol: json['stockSymbol'] as String,
      quantity: json['quantity'] as int,
      transactionPrice: (json['transactionPrice'] as num).toDouble(),
      buyingTime: parseBuyingTime(
        json['buyingTime'],
      ), // Use the safe parsing function
      charges: (json['charges'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      exchange: json['exchange'] as String,
      transactionType: json['transactionType'] as String,
    );
  }
}
