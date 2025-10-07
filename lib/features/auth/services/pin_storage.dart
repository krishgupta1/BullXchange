import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Provides secure, device-only storage for a user's 4-digit app PIN.
///
/// We never store the raw PIN. Instead we store a salted hash so that
/// even if secure storage is compromised, the original PIN cannot be
/// derived easily.
class PinStorageService {
  static const _pinKey = 'app_pin_hash_v1';
  static const _saltKey = 'app_pin_salt_v1';

  // Use default options for broadest platform compatibility.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Returns true if a PIN has been set on this device.
  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Sets the PIN after hashing with a random salt.
  Future<void> setPin(String pin) async {
    _assertValidPin(pin);
    final salt = _generateSalt();
    final hash = _hash(pin, salt);
    await _secureStorage.write(key: _saltKey, value: salt);
    await _secureStorage.write(key: _pinKey, value: hash);
  }

  /// Verifies an input against the stored hash.
  Future<bool> verifyPin(String pin) async {
    _assertValidPin(pin);
    final salt = await _secureStorage.read(key: _saltKey);
    final storedHash = await _secureStorage.read(key: _pinKey);
    if (salt == null || storedHash == null) return false;
    final inputHash = _hash(pin, salt);
    return fixedTimeComparison(storedHash, inputHash);
  }

  /// Clears the stored PIN (e.g., on logout).
  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _saltKey);
  }

  // --- Helpers ---
  void _assertValidPin(String pin) {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }
  }

  String _generateSalt() {
    // 16 cryptographically-secure random bytes, base64 encoded.
    final rand = Random.secure();
    final values = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(values);
  }

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Constant-time string comparison to mitigate timing attacks.
  bool fixedTimeComparison(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}


