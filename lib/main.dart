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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/services/expiry_service.dart';
import 'package:bullxchange/services/firebase/admin_config_service.dart';
import 'package:bullxchange/constants/api_constants.dart';

// --- main() function ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  // 🚀 Fetch Angel One configuration from Firestore
  final adminConfig = await AdminConfigService().fetchAngelOneConfig();
  if (adminConfig != null) {
    ApiConstants.updateFromFirestore(adminConfig);
  }

  // 🆓 FREE: Check expired positions on app startup (no paid services)
  await ExpiryService.checkAndCleanExpiredPositions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => InstrumentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs: prefs)),

        // --- ⭐️ THIS IS THE CRITICAL FIX ⭐️ ---
        // This stream listens to user data and handles logout gracefully
        StreamProvider<UserProfileDataModel?>.value(
          value: FirebaseAuth.instance.currentUser != null
              ? UserService().streamUserProfile(
                  FirebaseAuth.instance.currentUser!.uid,
                )
              : const Stream.empty(), // Return empty stream if not logged in
          initialData: null,
          // 🔴 IMPORTANT: This catchError prevents the "Permission Denied" crash
          catchError: (error, stackTrace) => null,
        ),
      ],
      child: const MainApp(),
    ),
  );
}

// --- MainApp widget (Unchanged from your code) ---
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

    // --- ⭐️ Determine which theme to use ---
    final ThemeData currentTheme = themeNotifier.themeMode == ThemeMode.dark
        ? AppTheme.getDarkTheme(context)
        : AppTheme.getLightTheme(context);

    return MaterialApp(
      title: 'BullXchange',
      debugShowCheckedModeBanner: false,

      // --- ⭐️ Sirf 'theme' property use karenge ---
      theme: currentTheme,

      routes: {'/home': (_) => const HomePage()},

      // --- ⭐️⭐️ Builder for smooth animation ⭐️⭐️ ---
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context), // Uses the theme calculated above
          duration: const Duration(milliseconds: 300),
          child: child!,
        );
      },

      // --- ⭐️⭐️ END FIX ⭐️⭐️ ---
      home: _showSplashScreen ? const SplashScreen() : const AuthWrapper(),
    );
  }
}
