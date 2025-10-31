import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart'; // Import new model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
  // Add a reference to the new transactions collection
  final CollectionReference transactionsRef = FirebaseFirestore.instance
      .collection('transactions');

  // --- Profile Management ---
  Future<void> addUserProfile({
    required String uid,
    required String name,
    required String emailId,
    required String mobileNo,
  }) async {
    final profile = UserProfileDataModel(
      uid: uid,
      name: name,
      emailId: emailId,
      mobileNo: mobileNo,
      accountCreationTime: DateTime.now(),
      stocks: const [],
    );
    try {
      await usersRef.doc(uid).set(profile.toJson());
      if (kDebugMode) print('User profile created for UID: $uid');
    } catch (e) {
      if (kDebugMode) print('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<UserProfileDataModel?> readUserProfile(String uid) async {
    final docSnapshot = await usersRef.doc(uid).get();
    if (docSnapshot.exists && docSnapshot.data() != null) {
      return UserProfileDataModel.fromJson(
        uid,
        docSnapshot.data() as Map<String, dynamic>,
      );
    }
    return null;
  }

  // --- NEW FUNCTION ---
  /// Adds a record of a single trade to the main 'transactions' collection.
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await transactionsRef.add(transaction.toJson());
      if (kDebugMode) {
        print('Transaction logged successfully for ${transaction.symbol}');
      }
    } catch (e) {
      if (kDebugMode) print('Error logging transaction: $e');
      rethrow;
    }
  }

  /// Updates the cumulative stock holding for a user.
  Future<void> updateCumulativeStockHolding(
    String uid,
    StockHoldingModel newStockTransaction,
  ) async {
    final docRef = usersRef.doc(uid);
    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        if (kDebugMode) print('User not found for UID: $uid');
        return;
      }
      final data = docSnap.data() as Map<String, dynamic>;
      final List<dynamic> stocksJson = data['stocks'] ?? [];
      List<StockHoldingModel> currentStocks = stocksJson
          .map(
            (json) =>
                StockHoldingModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();

      int existingIndex = currentStocks.indexWhere(
        (stock) =>
            stock.stockSymbol == newStockTransaction.stockSymbol &&
            stock.exchange == newStockTransaction.exchange &&
            stock.transactionType == newStockTransaction.transactionType,
      );

      if (existingIndex != -1) {
        final oldStock = currentStocks[existingIndex];
        final int totalQty = oldStock.quantity + newStockTransaction.quantity;
        if (totalQty <= 0) {
          currentStocks.removeAt(existingIndex);
        } else {
          final double totalValue =
              (oldStock.quantity * oldStock.transactionPrice) +
              (newStockTransaction.quantity *
                  newStockTransaction.transactionPrice);
          final double newAvgPrice = totalValue / totalQty;
          final double newTotalCharges =
              (oldStock.charges) + (newStockTransaction.charges);
          final double newTotalAmount =
              (oldStock.totalAmount) + (newStockTransaction.totalAmount);
          currentStocks[existingIndex] = StockHoldingModel(
            stockSymbol: oldStock.stockSymbol,
            stockName: oldStock.stockName,
            quantity: totalQty,
            transactionPrice: newAvgPrice,
            exchange: oldStock.exchange,
            transactionType: oldStock.transactionType,
            charges: newTotalCharges,
            totalAmount: newTotalAmount,
            buyingTime: newStockTransaction.buyingTime,
          );
        }
      } else if (newStockTransaction.quantity > 0) {
        currentStocks.add(newStockTransaction);
      }
      await docRef.update({
        'stocks': currentStocks.map((s) => s.toJson()).toList(),
      });
      if (kDebugMode) {
        print(
          'Cumulative stock holding updated for ${newStockTransaction.stockSymbol}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error updating cumulative stock holding: $e');
      rethrow;
    }
  }
}
