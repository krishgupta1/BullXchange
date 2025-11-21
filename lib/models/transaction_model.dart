import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id;
  final String userId;
  final String stockSymbol; // Dart variable name
  final String companyName;
  final String transactionType;
  final int quantity;
  final double price;
  final double charges;
  final double totalAmount;
  final String orderStatus;
  final DateTime transactionTime; // Dart variable name
  final String exchange;
  final String productType;
  final String orderType;

  TransactionModel({
    this.id,
    required this.userId,
    required this.stockSymbol,
    required this.companyName,
    required this.transactionType,
    required this.quantity,
    required this.price,
    required this.charges,
    required this.totalAmount,
    this.orderStatus = 'EXECUTED',
    required this.transactionTime,
    required this.exchange,
    required this.productType,
    required this.orderType,
  });

  /// Converts the model to a Map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      // 🛠️ FIX 1: Save as 'symbol' to match your existing Database
      'symbol': stockSymbol,
      'companyName': companyName,
      'transactionType': transactionType,
      'quantity': quantity,
      'price': price,
      'charges': charges,
      'totalAmount': totalAmount,
      'orderStatus': orderStatus,
      // 🛠️ FIX 2: Save as 'executedAt' so the Query works
      'executedAt': Timestamp.fromDate(transactionTime),
      'exchange': exchange,
      'productType': productType,
      'orderType': orderType,
    };
  }

  /// Creates a TransactionModel from a Firestore document snapshot.
  factory TransactionModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle Timestamp conversion safely
    // It looks for 'executedAt' (DB name) first.
    Timestamp? timeStamp = data['executedAt'] ?? data['transactionTime'];

    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      // Read 'symbol' from DB, map to 'stockSymbol' in Dart
      stockSymbol: data['symbol'] ?? data['stockSymbol'] ?? '',
      companyName: data['companyName'] ?? '',
      transactionType: data['transactionType'] ?? 'BUY',
      quantity: (data['quantity'] ?? 0).toInt(),
      price: (data['price'] ?? 0).toDouble(),
      charges: (data['charges'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      orderStatus: data['orderStatus'] ?? 'EXECUTED',
      transactionTime: timeStamp != null ? timeStamp.toDate() : DateTime.now(),
      exchange: data['exchange'] ?? 'NSE',
      productType: data['productType'] ?? 'Delivery',
      orderType: data['orderType'] ?? 'Market',
    );
  }
}
