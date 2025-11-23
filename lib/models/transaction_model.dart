import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id;
  final String userId;
  final String stockSymbol;
  final String companyName;
  final String transactionType;
  final int quantity;
  final double price;
  final double charges;
  final double totalAmount;
  final String orderStatus;
  final DateTime transactionTime;
  final String exchange;
  final String productType;
  final String orderType;

  // ⭐️ NEW FIELDS FOR OPTIONS
  final int? lotSize;
  final String? optionType;
  final String? expiryDate;
  final double? strikePrice;

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
    this.lotSize,
    this.optionType,
    this.expiryDate,
    this.strikePrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'symbol': stockSymbol,
      'companyName': companyName,
      'transactionType': transactionType,
      'quantity': quantity,
      'price': price,
      'charges': charges,
      'totalAmount': totalAmount,
      'orderStatus': orderStatus,
      'executedAt': Timestamp.fromDate(transactionTime),
      'exchange': exchange,
      'productType': productType,
      'orderType': orderType,
      // ⭐️ SAVE NEW FIELDS
      'lotSize': lotSize,
      'optionType': optionType,
      'expiryDate': expiryDate,
      'strikePrice': strikePrice,
    };
  }

  factory TransactionModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Timestamp? timeStamp = data['executedAt'] ?? data['transactionTime'];

    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
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
      // ⭐️ LOAD NEW FIELDS
      lotSize: data['lotSize'],
      optionType: data['optionType'],
      expiryDate: data['expiryDate'],
      strikePrice: (data['strikePrice'] as num?)?.toDouble(),
    );
  }
}
