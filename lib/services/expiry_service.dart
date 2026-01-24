import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:bullxchange/utils/option_calculator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ExpiryService {
  static final UserService _userService = UserService();
  static final CollectionReference _transactionsRef = 
      FirebaseFirestore.instance.collection('transactions');

  /// Check and clean expired positions (FREE - client-side only)
  static Future<void> checkAndCleanExpiredPositions() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      if (kDebugMode) print("🔍 Checking for expired positions...");
      
      final userProfile = await _userService.readUserProfile(uid);
      if (userProfile == null || userProfile.optionHoldings.isEmpty) return;

      final List<OptionHoldingModel> expiredPositions = [];
      final List<OptionHoldingModel> activePositions = [];

      // Separate expired and active positions
      for (var position in userProfile.optionHoldings) {
        final daysToExpiry = OptionCalculator.getDaysToExpiry(position.expiryDate);
        
        if (daysToExpiry < 0) {
          expiredPositions.add(position);
        } else {
          activePositions.add(position);
        }
      }

      if (expiredPositions.isNotEmpty) {
        if (kDebugMode) print("🗑️ Found ${expiredPositions.length} expired positions");
        
        // Process each expired position
        for (var expiredPos in expiredPositions) {
          await _processExpiredPosition(uid, expiredPos);
        }

        // Update user profile with only active positions
        await _updateUserPositions(uid, activePositions);
        
        if (kDebugMode) print("✅ Cleaned up ${expiredPositions.length} expired positions");
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error cleaning expired positions: $e");
    }
  }

  /// Process a single expired position
  static Future<void> _processExpiredPosition(String uid, OptionHoldingModel position) async {
    try {
      // Calculate final P&L (expired options are worth ₹0)
      final double finalPnl;
      if (position.quantity < 0) {
        // Short position: Profit = premium received
        finalPnl = position.investedAmount.abs();
      } else {
        // Long position: Loss = premium paid
        finalPnl = -position.investedAmount.abs();
      }

      // Create settlement transaction
      final settlementTransaction = TransactionModel(
        userId: uid,
        stockSymbol: position.contractSymbol,
        companyName: "${position.symbol} Expired",
        transactionType: 'EXPIRED',
        quantity: position.quantity,
        price: 0.0, // Expired options are worth ₹0
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

      // Save settlement transaction
      await _transactionsRef.add(settlementTransaction.toJson());
      
      if (kDebugMode) print("📝 Settlement created for ${position.contractSymbol}: ₹${finalPnl.toStringAsFixed(2)}");
      
    } catch (e) {
      if (kDebugMode) print("❌ Error processing expired position ${position.contractSymbol}: $e");
    }
  }

  /// Update user's positions to remove expired ones
  static Future<void> _updateUserPositions(String uid, List<OptionHoldingModel> activePositions) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      
      await userDocRef.update({
        'optionHoldings': activePositions.map((pos) => pos.toJson()).toList(),
      });
      
      if (kDebugMode) print("🔄 Updated: ${activePositions.length} active positions remaining");
      
    } catch (e) {
      if (kDebugMode) print("❌ Error updating user positions: $e");
    }
  }

  /// Get count of expired positions
  static Future<int> getExpiredPositionsCount() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 0;

      final userProfile = await _userService.readUserProfile(uid);
      if (userProfile == null) return 0;

      int expiredCount = 0;
      for (var position in userProfile.optionHoldings) {
        final daysToExpiry = OptionCalculator.getDaysToExpiry(position.expiryDate);
        if (daysToExpiry < 0) {
          expiredCount++;
        }
      }

      return expiredCount;
    } catch (e) {
      if (kDebugMode) print("❌ Error counting expired positions: $e");
      return 0;
    }
  }
}
