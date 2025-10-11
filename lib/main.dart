import 'package:bullxchange/provider/auth_provider.dart';
import 'package:bullxchange/features/auth/screens/splash_screen.dart';
import 'package:bullxchange/features/home/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bullxchange/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/auth/navigation/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LoginProvider())],
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
      routes: {'/home': (_) => const HomePage()},
      home: _showSplashScreen ? const SplashScreen() : const AuthWrapper(),
    );
  }
}
