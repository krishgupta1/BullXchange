import 'package:bullxchange/models/order_model.dart';
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
  final CollectionReference ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );

  // --- Stream for Recent Transactions (NO INDEX REQUIRED VERSION) ---
  // 1. Fetches data without specific database ordering (avoids "Missing Index" error).
  // 2. Sorts the data inside the app.
  Stream<List<TransactionModel>> streamRecentTransactions(String uid) {
    return transactionsRef
        .where('userId', isEqualTo: uid)
        // .orderBy(...) <--- REMOVED to avoid Index requirement
        .snapshots()
        .map((snapshot) {
          try {
            // Convert documents to Models
            List<TransactionModel> transactions = snapshot.docs
                .map((doc) => TransactionModel.fromSnapshot(doc))
                .toList();

            // SORT IN FLUTTER (Client-Side Sorting)
            // Sorts by transactionTime Descending (Newest first)
            transactions.sort(
              (a, b) => b.transactionTime.compareTo(a.transactionTime),
            );

            // LIMIT IN FLUTTER
            // Take only the top 10 after sorting
            if (transactions.length > 10) {
              return transactions.sublist(0, 10);
            }

            return transactions;
          } catch (e) {
            if (kDebugMode) {
              print('Error mapping transactions: $e');
            }
            return [];
          }
        });
  }

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
      positions: const [],
      watchlist: const [],
    );
    try {
      await usersRef.doc(uid).set(profile.toJson());
    } catch (e) {
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

  // --- Update Profile ---
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
    try {
      await usersRef.doc(uid).update(profileData);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      rethrow;
    }
  }

  // --- Atomic Trade Function (Used by Buy/Sell pages) ---
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

        List<StockHoldingModel> currentHoldings = List.from(
          currentUserProfile.stocks,
        );
        List<StockHoldingModel> currentPositions = List.from(
          currentUserProfile.positions,
        );

        bool isIntraday = stockHoldingUpdate.transactionType == 'INTRADAY';

        List<StockHoldingModel> listToUpdate = isIntraday
            ? currentPositions
            : currentHoldings;

        int existingIndex = listToUpdate.indexWhere(
          (stock) => stock.stockSymbol == stockHoldingUpdate.stockSymbol,
        );

        if (existingIndex != -1) {
          final oldStock = listToUpdate[existingIndex];
          final int totalQty = oldStock.quantity + stockHoldingUpdate.quantity;

          if (totalQty <= 0) {
            listToUpdate.removeAt(existingIndex);
          } else {
            double newAvgPrice = oldStock.transactionPrice;
            if (stockHoldingUpdate.quantity > 0) {
              final double totalValue =
                  (oldStock.quantity * oldStock.transactionPrice) +
                  (stockHoldingUpdate.quantity *
                      stockHoldingUpdate.transactionPrice);
              newAvgPrice = totalValue / totalQty;
            }

            listToUpdate[existingIndex] = oldStock.copyWith(
              quantity: totalQty,
              transactionPrice: newAvgPrice,
            );
          }
        } else if (stockHoldingUpdate.quantity > 0) {
          listToUpdate.add(stockHoldingUpdate);
        }

        firestoreTransaction.update(userDocRef, {
          'availableFunds': newFunds,
          'stocks': currentHoldings.map((s) => s.toJson()).toList(),
          'positions': currentPositions.map((p) => p.toJson()).toList(),
        });

        firestoreTransaction.set(newTransactionRef, transaction.toJson());
      });

      return newTransactionRef.id;
    } catch (e) {
      if (kDebugMode) {
        print("Failed to execute trade: $e");
      }
      rethrow;
    }
  }

  // --- FUNCTION TO PLACE A LIMIT ORDER ---
  Future<void> placeLimitOrder(OrderModel order) async {
    try {
      await ordersRef.add(order.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error placing limit order: $e');
      }
      rethrow;
    }
  }

  // --- STREAM FOR OPEN ORDERS ---
  Stream<List<OrderModel>> streamOpenOrders(String uid) {
    return ordersRef
        .where('userId', isEqualTo: uid)
        .where('orderStatus', isEqualTo: 'PENDING')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => OrderModel.fromSnapshot(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error mapping open orders: $e');
            }
            return [];
          }
        });
  }

  // --- FUNCTION TO CANCEL ALL PENDING ORDERS ---
  Future<void> cancelAllOrders(String uid) async {
    try {
      final querySnapshot = await ordersRef
          .where('userId', isEqualTo: uid)
          .where('orderStatus', isEqualTo: 'PENDING')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'orderStatus': 'CANCELLED'});
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling all orders: $e');
      }
      rethrow;
    }
  }

  // --- WATCHLIST FUNCTION ---
  Future<void> toggleWatchlistStock(String uid, String instrumentToken) async {
    final userDocRef = usersRef.doc(uid);

    try {
      final doc = await userDocRef.get();
      if (!doc.exists) {
        throw Exception("User profile not found.");
      }

      final data = doc.data() as Map<String, dynamic>;
      final List<String> currentWatchlist = List<String>.from(
        data['watchlist'] ?? [],
      );

      if (currentWatchlist.contains(instrumentToken)) {
        await userDocRef.update({
          'watchlist': FieldValue.arrayRemove([instrumentToken]),
        });
      } else {
        await userDocRef.update({
          'watchlist': FieldValue.arrayUnion([instrumentToken]),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling watchlist: $e');
      }
      rethrow;
    }
  }

  // --- Helper Functions ---

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
