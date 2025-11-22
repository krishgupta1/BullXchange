import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';

class PinStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns true if the current user has a PIN set in Firestore.
  Future<bool> hasPin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      // Check if the hash key exists and is not empty
      return data.containsKey('pinHash') &&
          data['pinHash'].toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Sets the PIN (Hashed) to the current user's Firestore document.
  Future<void> setPin(String pin) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User must be logged in to set a PIN");

    _assertValidPin(pin);

    final salt = _generateSalt();
    final hash = _hash(pin, salt);

    // Update the existing user document with the PIN data
    await _firestore.collection('users').doc(user.uid).update({
      'pinHash': hash,
      'pinSalt': salt,
      'pinUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verifies an input PIN against the Hash stored in Firestore.
  Future<bool> verifyPin(String pin) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _assertValidPin(pin);

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;

      final storedHash = data['pinHash'] as String?;
      final salt = data['pinSalt'] as String?;

      if (storedHash == null || salt == null) return false;

      final inputHash = _hash(pin, salt);

      // Compare the newly generated hash with the one from Firestore
      return fixedTimeComparison(storedHash, inputHash);
    } catch (e) {
      // If network fails or permission denied, fail safe to false
      return false;
    }
  }

  /// Clears the stored PIN from Firestore (Optional utility)
  Future<void> clearPin() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'pinHash': FieldValue.delete(),
        'pinSalt': FieldValue.delete(),
      });
    }
  }

  // --- Helpers (Same as before) ---
  void _assertValidPin(String pin) {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }
  }

  String _generateSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(values);
  }

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool fixedTimeComparison(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
