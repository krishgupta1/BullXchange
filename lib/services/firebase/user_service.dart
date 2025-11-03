import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async'; // Import dart:async for Stream

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference transactionsRef = FirebaseFirestore.instance
      .collection('transactions');

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
      positions: const [],
      watchlist: const [], // Initialize the new list
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

  // --- Stream Profile (Real-time updates) ---

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

  // --- Atomic Trade Function (for Holdings and Positions) ---

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

        // Check funds
        if (transaction.transactionType == 'BUY' &&
            currentFunds < transaction.totalAmount) {
          throw Exception("Insufficient funds to complete the purchase.");
        }

        double newFunds = (transaction.transactionType == 'BUY')
            ? currentFunds - transaction.totalAmount
            : currentFunds + transaction.totalAmount;

        // Determine which list to update (Stocks/Holdings or Positions/Intraday)
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
          // Update existing stock
          final oldStock = listToUpdate[existingIndex];
          final int totalQty = oldStock.quantity + stockHoldingUpdate.quantity;

          if (totalQty <= 0) {
            // Remove if quantity is zero or less
            listToUpdate.removeAt(existingIndex);
          } else {
            // Calculate new average price (only when buying)
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
          // Add new stock
          listToUpdate.add(stockHoldingUpdate);
        }

        // Update the user document in Firestore
        firestoreTransaction.update(userDocRef, {
          'availableFunds': newFunds,
          'stocks': currentHoldings.map((s) => s.toJson()).toList(),
          'positions': currentPositions.map((p) => p.toJson()).toList(),
        });

        // Log the transaction
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

  // --- Watchlist Management (FIXED FOR MINIMAL DATA) ---

  Future<void> toggleWatchlistItem({
    required String uid,
    required StockHoldingModel stockItem,
  }) async {
    final userDocRef = usersRef.doc(uid);

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

        List<StockHoldingModel> currentWatchlist = List.from(
          currentUserProfile.watchlist,
        );

        // Check if the item already exists in the watchlist
        int existingIndex = currentWatchlist.indexWhere(
          (stock) =>
              stock.stockSymbol == stockItem.stockSymbol &&
              stock.exchange == stockItem.exchange,
        );

        if (existingIndex != -1) {
          // If exists, remove it (TOGGLE OFF)
          currentWatchlist.removeAt(existingIndex);
        } else {
          // If it doesn't exist, add a MINIMAL version (TOGGLE ON)

          // We must create a new StockHoldingModel with minimal fields
          // because the data structure requires it.
          final minimalWatchlistItem = StockHoldingModel(
            stockSymbol: stockItem.stockSymbol,
            stockName: stockItem.stockName,
            exchange: stockItem.exchange,
            // Set all unnecessary fields to minimal/default values:
            quantity: 0,
            transactionPrice: 0.0,
            charges: 0.0,
            totalAmount: 0.0,
            transactionType: 'WLIST', // Indicate it's a watchlist entry
            buyingTime: DateTime.fromMillisecondsSinceEpoch(0),
          );

          currentWatchlist.add(minimalWatchlistItem);
        }

        // Update the user document in Firestore
        // ✨ FIX: Map the list back to JSON, ensuring only essential fields are present in new entries
        firestoreTransaction.update(userDocRef, {
          'watchlist': currentWatchlist.map((s) {
            // For new entries, this map ensures ONLY minimal fields are serialized:
            return {
              'stockSymbol': s.stockSymbol,
              'stockName': s.stockName,
              'exchange': s.exchange,
            };
          }).toList(),
        });
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Failed to toggle watchlist item: $e\n$stackTrace");
      }
      rethrow;
    }
  }

  // --- Order Management ---

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

  // --- Legacy/Redundant Function (Included for completeness but should be removed) ---

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

  // NOTE: updateCumulativeStockHolding is generally redundant if executeTrade is used exclusively.
  // We leave it here as it was part of the provided context.
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
