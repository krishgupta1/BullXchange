import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.1.dart';
import 'package:bullxchange/firebase_options.dart';
import 'package:bullxchange/features/auth/screens/onboarding/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          final offset = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(curved);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: _showSplash
            ? const SplashScreen(key: ValueKey('splash'))
            : const OnboardingPage(key: ValueKey('onboarding-1.1')),
      ),
    );
  }
}
