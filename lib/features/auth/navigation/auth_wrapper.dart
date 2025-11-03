import 'package:bullxchange/features/auth/screens/onboarding_page_1.1.dart';
import 'package:bullxchange/features/auth/screens/splash_screen.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';
import 'package:bullxchange/features/auth/screens/verify_pin_screen.dart';
import 'package:bullxchange/services/firebase/pin_storage.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    AppLog.d("--- Building AuthWrapper ---");

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        AppLog.d(
          "AuthWrapper StreamBuilder rebuilt. Connection state: ${snapshot.connectionState}",
        );

        // While the auth state is being determined...
        if (snapshot.connectionState == ConnectionState.waiting) {
          // --- THIS IS THE KEY CHANGE ---
          // Show your custom SplashScreen instead of a spinner.
          return const SplashScreen();
        }

        // If the snapshot has data, it means the user is logged in.
        if (snapshot.hasData) {
          AppLog.d(
            "➡️ AuthWrapper: User is LOGGED IN. Showing PinCheckWrapper.",
          );
          // Now, check if a PIN is set for this user.
          return const PinCheckWrapper();
        }

        // If there's no data, the user is logged out.
        AppLog.d("➡️ AuthWrapper: User is LOGGED OUT. Showing OnboardingPage.");
        return const OnboardingPage();
      },
    );
  }
}

// This widget checks if a local PIN has been set.
class PinCheckWrapper extends StatefulWidget {
  const PinCheckWrapper({super.key});
  @override
  State<PinCheckWrapper> createState() => _PinCheckWrapperState();
}

class _PinCheckWrapperState extends State<PinCheckWrapper> {
  late Future<bool> _hasPinFuture;
  final PinStorageService _pinStorage = PinStorageService();

  @override
  void initState() {
    super.initState();
    _hasPinFuture = _pinStorage.hasPin();
  }

  @override
  Widget build(BuildContext context) {
    AppLog.d("--- Building PinCheckWrapper ---");
    return FutureBuilder<bool>(
      future: _hasPinFuture,
      builder: (context, snapshot) {
        AppLog.d(
          "PinCheckWrapper FutureBuilder rebuilt. Connection state: ${snapshot.connectionState}",
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          // A spinner is fine here as this check is usually very fast.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          AppLog.w(
            "PinCheckWrapper: Error checking for PIN: ${snapshot.error}",
          );
          return const SetupPinScreen();
        }

        final hasPin = snapshot.data ?? false;

        if (hasPin) {
          AppLog.d("➡️ PinCheckWrapper: PIN exists. Showing VerifyPinScreen.");
          return const VerifyPinScreen();
        } else {
          AppLog.d("➡️ PinCheckWrapper: NO PIN. Showing SetupPinScreen.");
          return const SetupPinScreen();
        }
      },
    );
  }
}
