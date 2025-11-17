import 'package:bullxchange/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bullxchange/provider/auth_provider.dart';
import 'package:bullxchange/features/auth/screens/splash_screen.dart';
import 'package:bullxchange/features/home/screens/home_page.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bullxchange/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/auth/navigation/auth_wrapper.dart';

// --- main() function (Unchanged) ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => InstrumentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs: prefs)),
      ],
      child: const MainApp(),
    ),
  );
}

// --- MainApp widget (MODIFIED) ---
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showSplashScreen = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplashScreen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // --- ⭐️ FIX: Determine which theme to use ---
    // (Aapke settings mein Light/Dark hai, System nahi, isliye yeh safe hai)
    final ThemeData currentTheme = themeNotifier.themeMode == ThemeMode.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;

    return MaterialApp(
      title: 'BullXchange',
      debugShowCheckedModeBanner: false,

      // --- ⭐️ MODIFIED: Sirf 'theme' property use karenge ---
      // Isse AnimatedTheme ko pata chalta hai ki kab change karna hai
      theme: currentTheme,

      // 'darkTheme' aur 'themeMode' ki zaroorat nahi
      routes: {'/home': (_) => const HomePage()},

      // --- ⭐️⭐️ FIX: 'builder' add kiya smooth animation ke liye ⭐️⭐️ ---
      builder: (context, child) {
        return AnimatedTheme(
          // 'data' mein Theme.of(context) pass karein
          data: Theme.of(context),
          // Animation ka time (e.g., 300 milliseconds)
          duration: const Duration(milliseconds: 300),
          child: child!,
        );
      },

      // --- ⭐️⭐️ END FIX ⭐️⭐️ ---
      home: _showSplashScreen ? const SplashScreen() : const AuthWrapper(),
    );
  }
}
