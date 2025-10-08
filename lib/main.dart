import 'package:bullxchange/features/homepage/homepage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bullxchange/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- (Import the new files) ---
import 'package:bullxchange/features/auth/navigation/auth_wrapper.dart';

Future<void> main() async {
  // Ensures all bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If you use .env for API keys, load it here:
  await dotenv.load(fileName: ".env");

  runApp(const MainApp());
}

// --- (This widget is now much simpler) ---
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BullXchange',
      debugShowCheckedModeBanner: false,

      // Define the /home route to point to your actual home screen
      routes: {'/home': (_) => const HomePage()},

      // The AuthWrapper now controls what page is shown first.
      // It handles loading, login status, and PIN checks automatically.
      home: const AuthWrapper(),
    );
  }
}
