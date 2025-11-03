import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String userId;
  final String symbol;
  final String companyName;
  final String transactionType; // 'BUY' or 'SELL'
  final String orderType; // 'LIMIT'
  final String productType; // 'INTRADAY' or 'DELIVERY'
  final int quantity;
  final double limitPrice; // The price set by the user
  final String orderStatus; // 'PENDING', 'EXECUTED', 'CANCELLED'
  final DateTime createdAt;
  final String exchange;
  final String instrumentToken; // Storing token for faster lookup

  OrderModel({
    this.id,
    required this.userId,
    required this.symbol,
    required this.companyName,
    required this.transactionType,
    required this.orderType,
    required this.productType,
    required this.quantity,
    required this.limitPrice,
    this.orderStatus = 'PENDING',
    required this.createdAt,
    required this.exchange,
    required this.instrumentToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'symbol': symbol,
      'companyName': companyName,
      'transactionType': transactionType,
      'orderType': orderType,
      'productType': productType,
      'quantity': quantity,
      'limitPrice': limitPrice,
      'orderStatus': orderStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'exchange': exchange,
      'instrumentToken': instrumentToken,
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'],
      symbol: data['symbol'],
      companyName: data['companyName'],
      transactionType: data['transactionType'],
      orderType: data['orderType'],
      productType: data['productType'],
      quantity: data['quantity'],
      limitPrice: (data['limitPrice'] as num).toDouble(),
      orderStatus: data['orderStatus'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      exchange: data['exchange'],
      instrumentToken: data['instrumentToken'],
    );
  }
}
