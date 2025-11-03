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

  factory StockHoldingModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely read String fields
    String safeString(String key, String defaultValue) {
      return json[key] as String? ?? defaultValue;
    }

    // Helper function to safely parse the buyingTime field
    DateTime parseBuyingTime(dynamic timeData) {
      if (timeData is Timestamp) {
        return timeData.toDate();
      } else if (timeData is String) {
        return DateTime.tryParse(timeData) ?? DateTime.fromMillisecondsSinceEpoch(0);
      } else {
        // Fallback for missing or invalid data
        return DateTime.fromMillisecondsSinceEpoch(0); 
      }
    }
    
    // CRITICAL FIX: Safe casting for all numeric fields that might be null (like in the minimal watchlist entries)
    final quantityValue = (json['quantity'] as num?);
    final priceValue = (json['transactionPrice'] as num?);
    final chargesValue = (json['charges'] as num?);
    final totalValue = (json['totalAmount'] as num?);

    return StockHoldingModel(
      stockName: safeString('stockName', 'N/A'),
      stockSymbol: safeString('stockSymbol', 'N/A'),
      
      // Safety: Use ? and ?? to handle null or non-existent fields, defaulting to zero.
      quantity: quantityValue?.toInt() ?? 0,
      transactionPrice: priceValue?.toDouble() ?? 0.0,
      charges: chargesValue?.toDouble() ?? 0.0,
      totalAmount: totalValue?.toDouble() ?? 0.0,
      
      buyingTime: parseBuyingTime(
        json['buyingTime'],
      ), 
      exchange: safeString('exchange', 'NSE'),
      transactionType: safeString('transactionType', 'WLIST'),
    );
  }
}