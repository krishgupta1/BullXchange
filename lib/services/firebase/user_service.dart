import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  // --- Profile Management (No changes needed here) ---

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
      if (kDebugMode) {
        print('User profile created for UID: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user profile: $e');
      }
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

  Future<void> updateUserProfileFields(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await usersRef.doc(uid).update(data);
  }

  // --- Stock Transaction Logic (FIXED) ---

  /// **FIXED:** Updates the cumulative stock holding for a user.
  /// Holdings are unique based on Symbol, Exchange, AND TransactionType.
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
        // ✅ Stock holding exists -> update its values
        final oldStock = currentStocks[existingIndex];
        final int totalQty = oldStock.quantity + newStockTransaction.quantity;

        if (totalQty <= 0) {
          // If selling makes quantity zero or less, remove the holding
          currentStocks.removeAt(existingIndex);
          if (kDebugMode) {
            print(
              'Holding for ${newStockTransaction.stockSymbol} removed as quantity is now zero.',
            );
          }
        } else {
          // --- THIS IS THE CORRECTED LOGIC ---
          // 1. Calculate the new weighted average price
          final double totalValue =
              (oldStock.quantity * oldStock.transactionPrice) +
              (newStockTransaction.quantity *
                  newStockTransaction.transactionPrice);
          final double newAvgPrice = totalValue / totalQty;

          // 2. Accumulate charges and total amount invested
          final double newTotalCharges =
              (oldStock.charges) + (newStockTransaction.charges);
          final double newTotalAmount =
              (oldStock.totalAmount) + (newStockTransaction.totalAmount);

          // 3. Replace the old holding with an updated one, preserving all data
          currentStocks[existingIndex] = StockHoldingModel(
            stockSymbol: oldStock.stockSymbol,
            stockName: oldStock.stockName, // FIX: Preserved the stock name
            quantity: totalQty,
            transactionPrice: newAvgPrice, // The new calculated average price
            exchange: oldStock.exchange,
            transactionType: oldStock.transactionType,
            charges: newTotalCharges, // FIX: Accumulated charges
            totalAmount: newTotalAmount, // FIX: Accumulated total amount
            buyingTime: newStockTransaction
                .buyingTime, // FIX: Updated to latest transaction time
          );
          // --- END OF CORRECTION ---
        }
      } else if (newStockTransaction.quantity > 0) {
        // 🆕 New stock holding -> add it to the list
        // We only add if the quantity is positive (i.e., it's a buy transaction)
        currentStocks.add(newStockTransaction);
      }

      // Update Firestore with the modified list of holdings
      await docRef.update({
        'stocks': currentStocks.map((s) => s.toJson()).toList(),
      });

      if (kDebugMode) {
        print(
          'Cumulative stock holding updated successfully for ${newStockTransaction.stockSymbol}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error updating cumulative stock holding: $e');
      rethrow;
    }
  }

  // --- Utility Methods (No changes needed here) ---

  Future<void> deleteUser(String uid) async {
    await usersRef.doc(uid).delete();
  }

  Stream<QuerySnapshot> readUsers() {
    return usersRef.snapshots();
  }
}
