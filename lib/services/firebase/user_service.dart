// lib/services/user_service.dart
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection('users');

  // --- Profile Management ---

  /// Creates a new user profile document upon sign-up, using the model.
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

  /// Reads and returns the complete UserProfileDataModel for a given UID.
  Future<UserProfileDataModel?> readUserProfile(String uid) async {
    final docSnapshot = await usersRef.doc(uid).get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return UserProfileDataModel.fromJson(
          uid, docSnapshot.data() as Map<String, dynamic>);
    }
    return null;
  }
  
  /// Updates specific fields in a user document using a map for partial updates.
  Future<void> updateUserProfileFields(String uid, Map<String, dynamic> data) async {
    await usersRef.doc(uid).update(data);
  }

  // --- Stock Transaction Logic (Appending) ---

  /// Adds a new StockHoldingModel (which is a transaction record) to the 'stocks' array.
  /// Uses FieldValue.arrayUnion for efficient appending without reading the whole document first.
  Future<void> updateStockHolding(
      String uid, StockHoldingModel newTransaction) async {
    final userRef = usersRef.doc(uid);

    try {
      // arrayUnion efficiently appends the new transaction to the Firestore array
      await userRef.update({
        'stocks': FieldValue.arrayUnion([newTransaction.toJson()]),
      });
      if (kDebugMode) {
        print('Transaction added successfully for ${newTransaction.stockSymbol}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding transaction: $e');
      }
      // Re-throwing the error ensures the caller knows the operation failed
      rethrow; 
    }
  }

  // --- Utility Methods ---

  /// Deletes a user document.
  Future<void> deleteUser(String uid) async {
    await usersRef.doc(uid).delete();
  }

  /// Read all users as a stream.
  Stream<QuerySnapshot> readUsers() {
    return usersRef.snapshots();
  }
}
