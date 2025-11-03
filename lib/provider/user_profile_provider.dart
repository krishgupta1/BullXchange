import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UserProfileProvider with ChangeNotifier {
  final UserService _userService;
  final FirebaseAuth _auth;

  // Real-time user profile data
  UserProfileDataModel? _userProfile;
  UserProfileDataModel? get userProfile => _userProfile;

  // Subscription to the Firestore stream
  StreamSubscription<UserProfileDataModel?>? _profileSubscription;

  UserProfileProvider(this._userService, this._auth) {
    // Listen to authentication state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in: Start streaming their profile data
        _startListeningToProfile(user.uid);
      } else {
        // User logged out: Clear data
        _stopListeningToProfile();
      }
    });

    // Check for an already logged-in user right away (fixes initial load)
    if (_auth.currentUser != null) {
      _startListeningToProfile(_auth.currentUser!.uid);
    }
  }

  void _startListeningToProfile(String uid) {
    // 1. Cancel any existing subscription to prevent duplicates
    _profileSubscription?.cancel();

    // 2. Start a new subscription to the user's Firestore document
    // We rely on UserService.streamUserProfile(uid) to provide the data model
    _profileSubscription = _userService
        .streamUserProfile(uid)
        .listen(
          (profile) {
            // 3. Update the local model and notify widgets (like WatchlistPage)
            _userProfile = profile;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error streaming user profile: $error');
          },
        );
  }

  void _stopListeningToProfile() {
    // Clean up when the user logs out
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _userProfile = null;
    notifyListeners();
  }

  /// Exposes the raw watchlist array for use in any consuming widget.
  List<StockHoldingModel> get watchlist {
    return _userProfile?.watchlist ?? [];
  }

  /// Checks if a given stock symbol exists in the user's real-time watchlist.
  /// This is the method relied upon by the IconBookmarkButton.
  bool isStockInWatchlist(String stockSymbol) {
    if (_userProfile == null) return false;

    // Normalize the symbol by removing '-EQ' (e.g., "RELIANCE-EQ" -> "RELIANCE")
    // for reliable comparison with the symbol stored in the StockHoldingModel.
    final normalizedSymbol = stockSymbol.replaceAll('-EQ', '');

    return _userProfile!.watchlist.any(
      (item) => item.stockSymbol == normalizedSymbol,
    );
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
