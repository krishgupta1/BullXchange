import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:bullxchange/features/auth/screens/verify_pin_screen.dart';

// This class handles all the business logic for the login process.
class LoginProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Helper to update loading state and notify listeners.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // The main login function, moved from the LoginPage widget.
  Future<void> handleLogin(
    BuildContext context,
    String email,
    String password,
  ) async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(context, 'Please enter both email and password.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showErrorDialog(context, 'Please enter a valid email address.');
      return;
    }

    _setLoading(true);

    try {
      // Sign in with Firebase
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // If sign-in is successful, save the login state.
      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
      }

      if (!context.mounted) return;

      // Navigate to next screen
      Navigator.pushReplacement(
        context,
        slideRightToLeft(const VerifyPinScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          errorMessage =
              'This account has been disabled. Please contact support.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-credential':
          errorMessage = 'Incorrect email or password. Please try again.';
          break;
        default:
          errorMessage =
              'Login failed. Please check your credentials and try again.';
      }
      _showErrorDialog(context, errorMessage);
    } catch (e) {
      _showErrorDialog(context, 'An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Error dialog logic, also moved from the LoginPage widget.
  Future<void> _showErrorDialog(BuildContext context, String message) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }
}
