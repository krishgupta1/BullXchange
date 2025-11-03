import 'package:bullxchange/provider/auth_provider.dart';
import 'package:bullxchange/features/auth/screens/splash_screen.dart';
import 'package:bullxchange/features/home/screens/home_page.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/provider/user_profile_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart'; // <--- NEW IMPORT for the dependency
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bullxchange/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/auth/navigation/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- NEW IMPORT for FirebaseAuth

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        // 1. Core Services (must be provided first as others depend on it)
        Provider<UserService>(
          create: (_) => UserService(),
        ), // <--- ADDED UserService
        // 2. Auth Provider
        ChangeNotifierProvider(
          create: (_) => LoginProvider(),
        ), // Assuming LoginProvider is your AuthProvider
        // 3. Independent Providers
        ChangeNotifierProvider(create: (_) => InstrumentProvider()),

        // 4. Dependent Provider (UserProfileProvider)
        // We use ProxyProvider to pass the UserService instance and FirebaseAuth dependency.
        ChangeNotifierProxyProvider<UserService, UserProfileProvider>(
          // Note: The second generic type should be the type you are providing (UserProfileProvider).
          // ProxyProvider only needs one dependency type (UserService in this case).
          create: (context) => UserProfileProvider(
            context.read<UserService>(), // Dependency injection
            FirebaseAuth.instance, // Dependency injection
          ),
          update: (_, userService, userProfileProvider) => userProfileProvider!,
        ),
      ],
      child: const MainApp(),
    ),
  );
}

// --- The MainApp widget below is unchanged ---
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
    return MaterialApp(
      title: 'BullXchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'EudoxusSans',
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF4318FF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4318FF)),
      ),
      routes: {'/home': (_) => const HomePage()},
      home: _showSplashScreen ? const SplashScreen() : const AuthWrapper(),
    );
  }
}
