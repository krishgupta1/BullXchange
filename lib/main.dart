import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bullxchange/firebase_options.dart';

// Screens
import 'package:bullxchange/features/auth/screens/onboarding/splash_screen.dart';
import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.1.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Ensures all bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If you use .env for API keys, load it here:
  await dotenv.load(fileName: ".env");

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
    _startSplashTimer();
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BullXchange',
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (_) => const _HomePage(),
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          final offset = Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(curved);

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: _showSplash
            ? const SplashScreen()
            : const OnboardingPage(),
      ),
    );
  }
}

/// Minimal home page placeholder. Replace with the actual app home.
class _HomePage extends StatelessWidget {
  const _HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome!')),
    );
  }
}
