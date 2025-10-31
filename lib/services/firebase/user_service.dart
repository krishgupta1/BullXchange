// lib/services/user_service.dart
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference transactionsRef = FirebaseFirestore.instance
      .collection('transactions');

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
      availableFunds: 100000.0,
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

  /// Executes a trade, logs it, updates holdings, and manages virtual funds in a single atomic operation.
  Future<void> executeTrade({
    required String uid,
    required TransactionModel transaction,
    required StockHoldingModel stockHoldingUpdate,
  }) async {
    final userDocRef = usersRef.doc(uid);
    final newTransactionRef = transactionsRef.doc();

    try {
      await FirebaseFirestore.instance.runTransaction((
        firestoreTransaction,
      ) async {
        final userSnapshot = await firestoreTransaction.get(userDocRef);
        if (!userSnapshot.exists) {
          throw Exception("User does not exist!");
        }

        final currentUserProfile = UserProfileDataModel.fromJson(
          uid,
          userSnapshot.data() as Map<String, dynamic>,
        );
        final currentFunds = currentUserProfile.availableFunds;

        if (transaction.transactionType == 'BUY' &&
            currentFunds < transaction.totalAmount) {
          throw Exception("Insufficient funds to complete the purchase.");
        }

        double newFunds = (transaction.transactionType == 'BUY')
            ? currentFunds - transaction.totalAmount
            : currentFunds + transaction.totalAmount;

        List<StockHoldingModel> currentStocks = List.from(
          currentUserProfile.stocks,
        );
        int existingIndex = currentStocks.indexWhere(
          (stock) => stock.stockSymbol == stockHoldingUpdate.stockSymbol,
        );

        if (existingIndex != -1) {
          final oldStock = currentStocks[existingIndex];
          // For a sell, stockHoldingUpdate.quantity should be negative
          final int totalQty = oldStock.quantity + stockHoldingUpdate.quantity;

          if (totalQty <= 0) {
            currentStocks.removeAt(existingIndex);
          } else {
            final double totalValue =
                (oldStock.quantity * oldStock.transactionPrice) +
                (stockHoldingUpdate.quantity *
                    stockHoldingUpdate.transactionPrice);
            final double newAvgPrice = totalValue / totalQty;
            currentStocks[existingIndex] = oldStock.copyWith(
              quantity: totalQty,
              transactionPrice: newAvgPrice,
            );
          }
        } else if (stockHoldingUpdate.quantity > 0) {
          currentStocks.add(stockHoldingUpdate);
        }

        firestoreTransaction.update(userDocRef, {
          'availableFunds': newFunds,
          'stocks': currentStocks.map((s) => s.toJson()).toList(),
        });

        firestoreTransaction.set(newTransactionRef, transaction.toJson());
      });

      if (kDebugMode) print("Trade executed successfully!");
    } catch (e) {
      if (kDebugMode) print("Failed to execute trade: $e");
      rethrow; // This is now valid because it's inside a 'catch' block
    }
  }
}
