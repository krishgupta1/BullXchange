import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference transactionsRef = FirebaseFirestore.instance
      .collection('transactions');
  final CollectionReference ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );

  // ---------------------------------------------------------------------------
  // 1. PROFILE & AUTH METHODS
  // ---------------------------------------------------------------------------

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
      positions: const [],
      watchlist: const [],
      optionHoldings: const [],
    );
    await usersRef.doc(uid).set(profile.toJson());
  }

  Future<bool> isMobileNumberRegistered(String mobileNo) async {
    try {
      final QuerySnapshot result = await usersRef
          .where('mobileNo', isEqualTo: mobileNo)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String emailId,
    required String mobileNo,
  }) async {
    final profileData = {
      'name': name,
      'emailId': emailId,
      'mobileNo': mobileNo,
    };
    await usersRef.doc(uid).update(profileData);
  }

  // ---------------------------------------------------------------------------
  // 2. STOCK TRADING (EQUITY)
  // ---------------------------------------------------------------------------

  Future<String> executeTrade({
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
        if (!userSnapshot.exists) throw Exception("User does not exist!");

        final userProfile = UserProfileDataModel.fromJson(
          uid,
          userSnapshot.data() as Map<String, dynamic>,
        );

        if (transaction.transactionType == 'BUY' &&
            userProfile.availableFunds < transaction.totalAmount) {
          throw Exception("Insufficient funds.");
        }

        double newFunds = (transaction.transactionType == 'BUY')
            ? userProfile.availableFunds - transaction.totalAmount
            : userProfile.availableFunds + transaction.totalAmount;

        List<StockHoldingModel> currentList =
            stockHoldingUpdate.transactionType == 'INTRADAY'
            ? List.from(userProfile.positions)
            : List.from(userProfile.stocks);

        int index = currentList.indexWhere(
          (s) => s.stockSymbol == stockHoldingUpdate.stockSymbol,
        );

        if (index != -1) {
          final oldStock = currentList[index];
          final int newQty = oldStock.quantity + stockHoldingUpdate.quantity;

          if (newQty <= 0) {
            currentList.removeAt(index);
          } else {
            double newAvgPrice = oldStock.transactionPrice;
            if (stockHoldingUpdate.quantity > 0) {
              final double totalValue =
                  (oldStock.quantity * oldStock.transactionPrice) +
                  (stockHoldingUpdate.quantity *
                      stockHoldingUpdate.transactionPrice);
              newAvgPrice = totalValue / newQty;
            }

            currentList[index] = oldStock.copyWith(
              quantity: newQty,
              transactionPrice: newAvgPrice,
            );
          }
        } else if (stockHoldingUpdate.quantity > 0) {
          currentList.add(stockHoldingUpdate);
        }

        Map<String, dynamic> updateData = {'availableFunds': newFunds};
        if (stockHoldingUpdate.transactionType == 'INTRADAY') {
          updateData['positions'] = currentList.map((s) => s.toJson()).toList();
        } else {
          updateData['stocks'] = currentList.map((s) => s.toJson()).toList();
        }

        firestoreTransaction.update(userDocRef, updateData);
        firestoreTransaction.set(newTransactionRef, transaction.toJson());
      });

      return newTransactionRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. OPTION TRADING (F&O) - This saves to Transactions Collection
  // ---------------------------------------------------------------------------

  Future<String> executeOptionTrade({
    required String uid,
    required TransactionModel transaction,
    required OptionHoldingModel optionUpdate,
  }) async {
    final userDocRef = usersRef.doc(uid);
    // 1. Create a new Document Reference for the transaction
    final newTransactionRef = transactionsRef.doc();

    try {
      await FirebaseFirestore.instance.runTransaction((
        firestoreTransaction,
      ) async {
        final userSnapshot = await firestoreTransaction.get(userDocRef);
        if (!userSnapshot.exists) throw Exception("User does not exist!");

        final userProfile = UserProfileDataModel.fromJson(
          uid,
          userSnapshot.data() as Map<String, dynamic>,
        );

        // Check Funds
        if (transaction.transactionType == 'BUY' &&
            userProfile.availableFunds < transaction.totalAmount) {
          throw Exception("Insufficient funds.");
        }

        double newFunds = (transaction.transactionType == 'BUY')
            ? userProfile.availableFunds - transaction.totalAmount
            : userProfile.availableFunds + transaction.totalAmount;

        // Update Option Holdings
        List<OptionHoldingModel> currentOptions = List.from(
          userProfile.optionHoldings,
        );

        int index = currentOptions.indexWhere(
          (opt) =>
              opt.contractSymbol == optionUpdate.contractSymbol &&
              opt.transactionType == optionUpdate.transactionType,
        );

        if (index != -1) {
          final oldPos = currentOptions[index];
          int newQty = oldPos.quantity + optionUpdate.quantity;

          if (newQty <= 0) {
            currentOptions.removeAt(index);
          } else {
            double newAvg = oldPos.averagePrice;
            double newInvested = oldPos.investedAmount;

            if (optionUpdate.quantity > 0) {
              newInvested = oldPos.investedAmount + optionUpdate.investedAmount;
              newAvg = newInvested / newQty;
            } else {
              double soldPortion =
                  (optionUpdate.quantity.abs() / oldPos.quantity);
              newInvested = oldPos.investedAmount * (1 - soldPortion);
            }

            currentOptions[index] = oldPos.copyWith(
              quantity: newQty,
              averagePrice: newAvg,
              investedAmount: newInvested,
              currentLtp: optionUpdate.currentLtp,
            );
          }
        } else if (optionUpdate.quantity > 0) {
          currentOptions.add(optionUpdate);
        }

        // Update User Funds & Holdings
        firestoreTransaction.update(userDocRef, {
          'availableFunds': newFunds,
          'optionHoldings': currentOptions.map((o) => o.toJson()).toList(),
        });

        // 2. ⭐️ THIS SAVES THE TRANSACTION HISTORY ⭐️
        if (kDebugMode) {
          print("Saving Transaction: ${transaction.toJson()}");
        }
        firestoreTransaction.set(newTransactionRef, transaction.toJson());
      });

      return newTransactionRef.id;
    } catch (e) {
      if (kDebugMode) print("Option Trade Error: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. ORDERS & WATCHLIST & TRANSACTIONS (READING)
  // ---------------------------------------------------------------------------

  // ⭐️ UPDATED: Added Error Logging so you can see why data might be hidden
  Stream<List<TransactionModel>> streamRecentTransactions(String uid) {
    return transactionsRef.where('userId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      try {
        // Map each document individually to catch specific errors
        List<TransactionModel> transactions = [];

        for (var doc in snapshot.docs) {
          try {
            transactions.add(TransactionModel.fromSnapshot(doc));
          } catch (e) {
            // 🔴 If a transaction is failing to load, this will print WHY
            if (kDebugMode) {
              print("Error parsing transaction doc ${doc.id}: $e");
            }
          }
        }

        // Sort by time (Newest first)
        transactions.sort(
          (a, b) => b.transactionTime.compareTo(a.transactionTime),
        );

        if (transactions.length > 10) return transactions.sublist(0, 10);
        return transactions;
      } catch (e) {
        if (kDebugMode) print("Global Transaction Stream Error: $e");
        return [];
      }
    });
  }

  Future<void> placeLimitOrder(OrderModel order) async {
    await ordersRef.add(order.toJson());
  }

  Stream<List<OrderModel>> streamOpenOrders(String uid) {
    return ordersRef
        .where('userId', isEqualTo: uid)
        .where('orderStatus', isEqualTo: 'PENDING')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList(),
        );
  }

  Future<void> cancelAllOrders(String uid) async {
    try {
      final querySnapshot = await ordersRef
          .where('userId', isEqualTo: uid)
          .where('orderStatus', isEqualTo: 'PENDING')
          .get();

      if (querySnapshot.docs.isEmpty) return;

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'orderStatus': 'CANCELLED'});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('Error cancelling all orders: $e');
      rethrow;
    }
  }

  Future<void> toggleWatchlistStock(String uid, String instrumentToken) async {
    final userDocRef = usersRef.doc(uid);
    final doc = await userDocRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final List<String> current = List<String>.from(data['watchlist'] ?? []);

      if (current.contains(instrumentToken)) {
        await userDocRef.update({
          'watchlist': FieldValue.arrayRemove([instrumentToken]),
        });
      } else {
        await userDocRef.update({
          'watchlist': FieldValue.arrayUnion([instrumentToken]),
        });
      }
    }
  }
}
