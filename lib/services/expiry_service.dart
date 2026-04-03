import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ExpiryService {
  static final UserService _userService = UserService();

  static final CollectionReference _transactionsRef =
      FirebaseFirestore.instance.collection('transactions');

  /// NSE options expire at 3:30 PM IST
  static DateTime _getExpiryDateTime(DateTime expiryDate) {
    return DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      15,
      30,
    );
  }

  /// Check if option has expired (expiryDate as String)
  static bool _isExpired(String expiryDateStr) {
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final now = DateTime.now();
      final expiryDateTime = _getExpiryDateTime(expiryDate);
      return now.isAfter(expiryDateTime);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error parsing expiry date: $expiryDateStr");
      }
      return false; // Assume not expired if date is invalid
    }
  }

  /// Check and clean expired positions
  static Future<void> checkAndCleanExpiredPositions() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      if (kDebugMode) {
        print("🔍 Checking for expired positions...");
      }

      final userProfile = await _userService.readUserProfile(uid);

      if (userProfile == null || userProfile.optionHoldings.isEmpty) {
        return;
      }

      final List<OptionHoldingModel> expiredPositions = [];
      final List<OptionHoldingModel> activePositions = [];

      for (var position in userProfile.optionHoldings) {
        if (_isExpired(position.expiryDate)) {
          expiredPositions.add(position);
        } else {
          activePositions.add(position);
        }
      }

      if (expiredPositions.isEmpty) return;

      if (kDebugMode) {
        print("🗑️ Found ${expiredPositions.length} expired positions");
      }

      for (var expiredPos in expiredPositions) {
        await _processExpiredPosition(uid, expiredPos);
      }

      await _updateUserPositions(uid, activePositions);

      if (kDebugMode) {
        print("✅ Cleaned ${expiredPositions.length} expired positions");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cleaning expired positions: $e");
      }
    }
  }

  /// Process expired option settlement
  static Future<void> _processExpiredPosition(
      String uid, OptionHoldingModel position) async {
    try {
      double finalPnl = 0;

      /// Long option → premium lost
      if (position.quantity > 0) {
        finalPnl = -position.investedAmount.abs();
      }

      /// Short option → premium kept
      if (position.quantity < 0) {
        finalPnl = position.investedAmount.abs();
      }

      final settlementTransaction = TransactionModel(
        userId: uid,
        stockSymbol: position.contractSymbol,
        companyName: "${position.symbol} Expired",
        transactionType: 'EXPIRED',
        quantity: position.quantity,
        price: 0.0,
        charges: 0.0,
        totalAmount: finalPnl,
        exchange: position.exchange,
        productType: position.transactionType,
        orderType: 'SETTLEMENT',
        transactionTime: DateTime.now(),
        lotSize: position.lotSize,
        optionType: position.optionType,
        strikePrice: position.strikePrice,
        expiryDate: position.expiryDate,
        target: null,
        stopLoss: null,
      );

      await _transactionsRef.add(settlementTransaction.toJson());

      if (kDebugMode) {
        print(
            "📝 Settlement created for ${position.contractSymbol}: ₹${finalPnl.toStringAsFixed(2)}");
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            "❌ Error processing expired position ${position.contractSymbol}: $e");
      }
    }
  }

  /// Update user's remaining active positions
  static Future<void> _updateUserPositions(
      String uid, List<OptionHoldingModel> activePositions) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userDocRef.update({
        'optionHoldings': activePositions.map((pos) => pos.toJson()).toList(),
      });

      if (kDebugMode) {
        print("🔄 Updated: ${activePositions.length} active positions remaining");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error updating user positions: $e");
      }
    }
  }

  /// Get number of expired positions
  static Future<int> getExpiredPositionsCount() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 0;

      final userProfile = await _userService.readUserProfile(uid);
      if (userProfile == null) return 0;

      int expiredCount = 0;

      for (var position in userProfile.optionHoldings) {
        if (_isExpired(position.expiryDate)) {
          expiredCount++;
        }
      }

      return expiredCount;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error counting expired positions: $e");
      }
      return 0;
    }
  }
}