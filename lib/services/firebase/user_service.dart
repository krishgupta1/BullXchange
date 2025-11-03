// lib/services/firebase/user_service.dart
import 'package:bullxchange/models/order_model.dart'; // <-- 1. IMPORT ORDER MODEL
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

  // --- 2. ADD ORDERS COLLECTION REFERENCE ---
  final CollectionReference ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );

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
      positions: const [], // Make sure to initialize the new list
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

        // Check funds (this logic is the same for both types)
        if (transaction.transactionType == 'BUY' &&
            currentFunds < transaction.totalAmount) {
          throw Exception("Insufficient funds to complete the purchase.");
        }

        double newFunds = (transaction.transactionType == 'BUY')
            ? currentFunds - transaction.totalAmount
            : currentFunds + transaction.totalAmount;

        // --- THIS IS THE NEW ROUTING LOGIC ---

        // Get mutable copies of both lists
        List<StockHoldingModel> currentHoldings = List.from(
          currentUserProfile.stocks,
        );
        List<StockHoldingModel> currentPositions = List.from(
          currentUserProfile.positions,
        );

        // Determine which list to update
        bool isIntraday = stockHoldingUpdate.transactionType == 'INTRADAY';

        List<StockHoldingModel> listToUpdate = isIntraday
            ? currentPositions
            : currentHoldings;

        int existingIndex = listToUpdate.indexWhere(
          (stock) => stock.stockSymbol == stockHoldingUpdate.stockSymbol,
        );

        if (existingIndex != -1) {
          // Stock already exists in the list, update it
          final oldStock = listToUpdate[existingIndex];
          final int totalQty = oldStock.quantity + stockHoldingUpdate.quantity;

          if (totalQty <= 0) {
            // Remove from list if quantity is zero or less
            listToUpdate.removeAt(existingIndex);
          } else {
            // Calculate new average price (only if it's a BUY)
            double newAvgPrice = oldStock.transactionPrice;
            if (stockHoldingUpdate.quantity > 0) {
              // It's a BUY
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
          // New stock, add to the list
          listToUpdate.add(stockHoldingUpdate);
        }

        // --- END OF NEW ROUTING LOGIC ---

        // Update the user document in Firestore
        firestoreTransaction.update(userDocRef, {
          'availableFunds': newFunds,

          // Update both lists in Firestore
          'stocks': currentHoldings.map((s) => s.toJson()).toList(),
          'positions': currentPositions.map((p) => p.toJson()).toList(),
        });

        // Log the transaction (this is the same)
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

  // --- 3. NEW FUNCTION TO PLACE A LIMIT ORDER ---
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

  // --- 4. NEW STREAM FOR OPEN ORDERS ---
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

  // NOTE: This function is now redundant because executeTrade handles all its logic.
  // You can safely remove it if you are no longer calling it from anywhere.
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
