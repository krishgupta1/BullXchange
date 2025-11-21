import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FundService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. USER: Submits a request to database
  Future<void> submitFundRequest({
    required double amountInRupees,
    required int coins,
    required String utr,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db.collection('fund_requests').add({
      'uid': user.uid,
      'email': user.email ?? 'Unknown',
      'amount_rs': amountInRupees,
      'coins_to_add': coins,
      'utr_number': utr,
      'status': 'pending', // pending, approved, rejected
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 2. ADMIN: Approves request & Adds Coins in ONE transaction
  Future<void> approveRequest(String requestId, String userId, int coins) async {
    await _db.runTransaction((transaction) async {
      DocumentReference requestRef = _db.collection('fund_requests').doc(requestId);
      DocumentReference userRef = _db.collection('users').doc(userId);

      DocumentSnapshot requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) throw Exception("Request not found");
      
      // Check if already processed to prevent double addition
      if (requestSnapshot.get('status') == 'approved') {
        throw Exception("Request already approved");
      }

      // Update Request Status
      transaction.update(requestRef, {'status': 'approved'});

      // Update User Wallet (Create field if not exists)
      DocumentSnapshot userSnapshot = await transaction.get(userRef);
      if (userSnapshot.exists) {
        double currentBalance = (userSnapshot.data() as Map)['walletBalance']?.toDouble() ?? 0.0;
        transaction.update(userRef, {'walletBalance': currentBalance + coins});
      } else {
        // If user doc doesn't exist, create it
        transaction.set(userRef, {'walletBalance': coins});
      }
    });
  }

  // 3. ADMIN: Rejects Request
  Future<void> rejectRequest(String requestId) async {
    await _db.collection('fund_requests').doc(requestId).update({
      'status': 'rejected'
    });
  }
}