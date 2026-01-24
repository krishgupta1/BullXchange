import 'dart:math'; // Required for Random
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/utils/option_calculator.dart';
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
  final CollectionReference fundsRef = FirebaseFirestore.instance.collection(
    'fund_requests',
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

  Future<bool> validateReferralCode(String code) async {
    if (code.isEmpty) return true;
    try {
      final querySnapshot = await usersRef
          .where('myReferralCode', isEqualTo: code)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print("Referral Validation Error: $e");
      return false;
    }
  }

  // ⭐️ UPDATED: Separated Logic to ensure History is always created
  Future<void> addUserProfile({
    required String uid,
    required String name,
    required String emailId,
    required String mobileNo,
    String? referralCode,
  }) async {
    // 1. Define Defaults & Bonus Amounts
    double startingFunds = 100000.0;
    const double referrerBonus = 10000.0;
    const double refereeBonus = 5000.0;

    // 2. Generate Unique Referral Code
    String cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (cleanName.length > 4) {
      cleanName = cleanName.substring(0, 4);
    } else if (cleanName.isEmpty) {
      cleanName = "BULL";
    }

    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random rnd = Random();
    String randomSuffix = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    String myNewReferralCode = "$cleanName$randomSuffix";

    DocumentReference? referrerRef;
    String? referrerUid;

    // 3. Check if Referral Code is Valid
    bool isReferralValid = false;
    if (referralCode != null && referralCode.isNotEmpty) {
      try {
        final querySnapshot = await usersRef
            .where('myReferralCode', isEqualTo: referralCode)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          referrerRef = querySnapshot.docs.first.reference;
          referrerUid = querySnapshot.docs.first.id;
          isReferralValid = true;
          // Apply Bonus to Starting Funds
          startingFunds += refereeBonus;
        }
      } catch (e) {
        if (kDebugMode) print("Error finding referrer: $e");
      }
    }

    // 4. PREPARE USER DATA
    final profile = UserProfileDataModel(
      uid: uid,
      name: name,
      emailId: emailId,
      mobileNo: mobileNo,
      accountCreationTime: DateTime.now(),
      availableFunds: startingFunds, // Includes 5000 bonus if valid
      stocks: const [],
      positions: const [],
      watchlist: const [],
      optionHoldings: const [],
    );

    final Map<String, dynamic> userData = profile.toJson();
    userData['myReferralCode'] = myNewReferralCode;
    if (isReferralValid) {
      userData['referredBy'] = referralCode;
    }

    // 5. ⭐️ STEP 1: CREATE USER PROFILE (Critical)
    // We do this separately so the user account is GUARANTEED to exist
    await usersRef.doc(uid).set(userData);

    // 6. ⭐️ STEP 2: CREATE HISTORY ENTRY FOR NEW USER
    // Only if they used a referral code
    if (isReferralValid) {
      try {
        await fundsRef.add({
          'uid': uid,
          'amount_rs': refereeBonus,
          'utr_number': 'JOINING BONUS',
          'status': 'approved',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'REFERRAL_BONUS',
        });
      } catch (e) {
        if (kDebugMode) print("Failed to create user history: $e");
      }

      // 7. ⭐️ STEP 3: UPDATE REFERRER (Best Effort)
      // We try this last. If it fails (due to permissions), it won't break the new user's experience.
      if (referrerRef != null && referrerUid != null) {
        try {
          // Use FieldValue.increment for safety
          await referrerRef.update({
            'availableFunds': FieldValue.increment(referrerBonus),
          });

          // Add Referrer History
          await fundsRef.add({
            'uid': referrerUid,
            'amount_rs': referrerBonus,
            'utr_number': 'REF: $name',
            'status': 'approved',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'REFERRAL_BONUS',
          });
        } catch (e) {
          // This typically fails if Firestore rules block User A from updating User B
          if (kDebugMode) {
            print("Referrer update skipped (Permission/Error): $e");
          }
        }
      }
    }
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
  // 3. OPTION TRADING (F&O)
  // ---------------------------------------------------------------------------

  Future<String> executeOptionTrade({
    required String uid,
    required TransactionModel transaction,
    required OptionHoldingModel optionUpdate,
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
        } else {
          // Add new position (both long and short positions)
          // Calculate time decay data
          final daysToExpiry = OptionCalculator.getDaysToExpiry(optionUpdate.expiryDate);
          final theta = OptionCalculator.calculateThetaImpact(optionUpdate.averagePrice, daysToExpiry);
          final thetaPercent = OptionCalculator.getTimeDecayPercent(optionUpdate.averagePrice, daysToExpiry);
          
          final enrichedOptionUpdate = optionUpdate.copyWith(
            theta: theta,
            thetaPercent: thetaPercent,
            daysToExpiry: daysToExpiry,
          );
          
          currentOptions.add(enrichedOptionUpdate);
        }

        firestoreTransaction.update(userDocRef, {
          'availableFunds': newFunds,
          'optionHoldings': currentOptions.map((o) => o.toJson()).toList(),
        });

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

  Stream<List<TransactionModel>> streamRecentTransactions(String uid) {
    return transactionsRef.where('userId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      try {
        List<TransactionModel> transactions = [];
        for (var doc in snapshot.docs) {
          try {
            transactions.add(TransactionModel.fromSnapshot(doc));
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing transaction doc ${doc.id}: $e");
            }
          }
        }
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
