import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AngelOneService {
  static final CollectionReference _adminConfigRef = FirebaseFirestore.instance
      .collection('admin_config');

  static String? _cachedJwtToken;
  static DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(
    minutes: 15,
  ); // Cache for 15 minutes (reduced from 30)

  /// Fetch JWT token from Firebase Firestore
  static Future<String?> getJwtToken() async {
    // Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print('❌ No authenticated user found - cannot fetch JWT token');
      }
      return null;
    }

    // Check if we have a cached token that's still valid
    if (_cachedJwtToken != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheTimeout) {
      if (kDebugMode) {
        print('🔄 Using cached JWT token');
      }
      return _cachedJwtToken;
    }

    try {
      if (kDebugMode) {
        print('🔄 Fetching JWT token from Firebase...');
      }

      final DocumentSnapshot doc = await _adminConfigRef.doc('angelone').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final jwtToken = data['jwtToken'] as String?;

        if (jwtToken != null && jwtToken.isNotEmpty) {
          _cachedJwtToken = jwtToken;
          _lastFetchTime = DateTime.now();

          if (kDebugMode) {
            print('✅ Successfully fetched JWT token from Firebase');
          }
          return jwtToken;
        } else {
          if (kDebugMode) {
            print('❌ JWT token is null or empty in Firebase');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Angel One config document not found in Firebase');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching JWT token from Firebase: $e');
      }
    }

    return null;
  }

  /// Store JWT token to Firebase Firestore (admin function)
  static Future<bool> storeJwtToken(String jwtToken, String clientCode) async {
    // Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print('❌ No authenticated user found - cannot store JWT token');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        print('🔄 Storing JWT token to Firebase...');
      }

      await _adminConfigRef.doc('angelone').set({
        'jwtToken': jwtToken,
        'clientCode': clientCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache to force refresh on next read
      _cachedJwtToken = null;
      _lastFetchTime = null;

      if (kDebugMode) {
        print('✅ Successfully stored JWT token to Firebase');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing JWT token to Firebase: $e');
      }
      return false;
    }
  }

  /// Clear cached JWT token (useful for testing or forced refresh)
  static void clearCache() {
    _cachedJwtToken = null;
    _lastFetchTime = null;
    if (kDebugMode) {
      print('🗑️ JWT token cache cleared');
    }
  }

  /// Check if JWT token is cached and still valid
  static bool isTokenCached() {
    return _cachedJwtToken != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheTimeout;
  }

  /// Handle invalid JWT token by clearing cache and forcing refresh
  static void handleInvalidToken() {
    if (kDebugMode) {
      print('🗑️ Invalid JWT token detected - clearing cache');
    }
    clearCache();
  }

  /// Clear invalid JWT token from Firebase (call when token is persistently invalid)
  static Future<void> clearInvalidTokenFromFirebase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('❌ No authenticated user found - cannot clear token from Firebase');
        }
        return;
      }

      if (kDebugMode) {
        print('🗑️ Clearing invalid JWT token from Firebase...');
      }

      // Clear the token from Firebase
      await _adminConfigRef.doc('angelone').update({
        'jwtToken': FieldValue.delete(),
        'clearedAt': FieldValue.serverTimestamp(),
      });

      // Clear local cache
      clearCache();

      if (kDebugMode) {
        print('✅ Invalid JWT token cleared from Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing JWT token from Firebase: $e');
      }
    }
  }
}
