import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.1.dart';
import 'package:bullxchange/features/auth/screens/pages/setup_pin_screen.dart';
import 'package:bullxchange/features/auth/screens/pages/verify_pin_screen.dart';
import 'package:bullxchange/features/auth/services/pin_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("--- Building AuthWrapper ---");

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
          "AuthWrapper StreamBuilder rebuilt. Connection state: ${snapshot.connectionState}",
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          debugPrint(
            "➡️ AuthWrapper: User is LOGGED IN. Showing PinCheckWrapper.",
          );
          return const PinCheckWrapper();
        }

        debugPrint(
          "➡️ AuthWrapper: User is LOGGED OUT. Showing OnboardingPage.",
        );
        return const OnboardingPage();
      },
    );
  }
}

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
    debugPrint("--- Building PinCheckWrapper ---");
    return FutureBuilder<bool>(
      future: _hasPinFuture,
      builder: (context, snapshot) {
        debugPrint(
          "PinCheckWrapper FutureBuilder rebuilt. Connection state: ${snapshot.connectionState}",
        );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          debugPrint(
            "PinCheckWrapper: Error checking for PIN: ${snapshot.error}",
          );
          return const SetupPinScreen();
        }
        final hasPin = snapshot.data ?? false;
        if (hasPin) {
          debugPrint(
            "➡️ PinCheckWrapper: PIN exists. Showing VerifyPinScreen.",
          );
          return const VerifyPinScreen();
        } else {
          debugPrint("➡️ PinCheckWrapper: NO PIN. Showing SetupPinScreen.");
          return const SetupPinScreen();
        }
      },
    );
  }
}
