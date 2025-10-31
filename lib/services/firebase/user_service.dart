// lib/services/firebase/user_service.dart
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Still needed for kDebugMode if you keep any
// Note: I'm removing all kDebugMode prints as requested.

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
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
      availableFunds: 100000.0,
      stocks: const [],
    );
    try {
      await usersRef.doc(uid).set(profile.toJson());
    } catch (e) {
      // You can keep one print here for critical errors
      if (kDebugMode) {
        print('Error creating user profile: $e');
      }
      rethrow;
    }
  }

  // --- Read Profile (One-time fetch) ---
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

  // --- Stream Profile (Real-time updates for Holdings) ---
  Stream<UserProfileDataModel?> streamUserProfile(String uid) {
    final docRef = usersRef.doc(uid);
    return docRef.snapshots().map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserProfileDataModel.fromJson(
          uid,
          docSnapshot.data() as Map<String, dynamic>,
        );
      }
      return null;
    });
  }

  // --- Atomic Trade Function (Used by Buy/Sell pages) ---
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
          final int totalQty = oldStock.quantity + stockHoldingUpdate.quantity;

          if (totalQty <= 0) {
            currentStocks.removeAt(existingIndex);
          } else {
            // Calculate new average price
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

      // Removed success print
    } catch (e) {
      // It's often good to keep error prints
      if (kDebugMode) {
        print("Failed to execute trade: $e");
      }
      rethrow;
    }
  }

  // --- Your Original Functions (Kept for reference) ---

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await transactionsRef.add(transaction.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error logging transaction: $e');
      }
      rethrow;
    }
  }

  Future<void> updateCumulativeStockHolding(
    String uid,
    StockHoldingModel newStockTransaction,
  ) async {
    final docRef = usersRef.doc(uid);
    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        // Kept this one as it's a specific warning
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
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cumulative stock holding: $e');
      }
      rethrow;
    }
  }
}