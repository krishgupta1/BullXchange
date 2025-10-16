import 'package:bullxchange/provider/auth_provider.dart';
import 'package:bullxchange/provider/market_provider.dart';
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
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(
          create: (_) => StocksProvider(
            jwtToken:
                "eyJhbGciOiJIUzUxMiJ9.eyJ1c2VybmFtZSI6IkFBQU83ODQzOTMiLCJyb2xlcyI6MCwidXNlcnR5cGUiOiJVU0VSIiwidG9rZW4iOiJleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKMWMyVnlYM1I1Y0dVaU9pSmpiR2xsYm5RaUxDSjBiMnRsYmw5MGVYQmxJam9pZEhKaFpHVmZZV05qWlhOelgzUnZhMlZ1SWl3aVoyMWZhV1FpT2pNc0luTnZkWEpqWlNJNklqTWlMQ0prWlhacFkyVmZhV1FpT2lJNE16a3paVEl5T0MweE1ESXhMVE0zTmpJdE9URmtZUzAwWlRNNU1HRTVOVE0yTWpRaUxDSnJhV1FpT2lKMGNtRmtaVjlyWlhsZmRqSWlMQ0p2Ylc1bGJXRnVZV2RsY21sa0lqb3pMQ0p3Y205a2RXTjBjeUk2ZXlKa1pXMWhkQ0k2ZXlKemRHRjBkWE1pT2lKaFkzUnBkbVVpZlN3aWJXWWlPbnNpYzNSaGRIVnpJam9pWVdOMGFYWmxJbjE5TENKcGMzTWlPaUowY21Ga1pWOXNiMmRwYmw5elpYSjJhV05sSWl3aWMzVmlJam9pUVVGQlR6YzRORE01TXlJc0ltVjRjQ0k2TVRjMk1EWTBNak15Tml3aWJtSm1Jam94TnpZd05UVTFOelEyTENKcFlYUWlPakUzTmpBMU5UVTNORFlzSW1wMGFTSTZJbVZrWWprelpqUmtMV1UyTWpRdE5HRmtNeTA0WVRNNUxUTTNaR1EyTVdSa01ETTFOQ0lzSWxSdmEyVnVJam9pSW4wLmRUOXNNd3ZJcHpGZDMyUERqc0czam4tNEo2ZkpuVmZGaHdpX1hvdWxlVGkxYUIxSWJuM0N4Nml1SEthUEV5enVobzdza2x4TzRuWE82bHZLYk53MTBNdm9yRW9MOE1pYldfb2UyY2llRW9vZXF1UzhFUFBWeTBIekFuMGRmZUxYWGpRemVOUU5xZW5FaklDS2Nrb1RCYWpNenhpenJvX1NHb3YyZ3NCSGJrVSIsIkFQSS1LRVkiOiJOZGNvUFhCSyIsIlgtT0xELUFQSS1LRVkiOmZhbHNlLCJpYXQiOjE3NjA1NTU5MjYsImV4cCI6MTc2MDYzOTQwMH0.gJnjdEZyWu3_SoWzKpugjKBbFYZy_XV4KwN9XcWQ78103lp-hodfXA0X9r6YIw8e6gnyX5h52D2wpfKBI38dpw", // ✅ Replace with actual token
            apiKey: "NdcoPXBK",
            clientIP: "152.58.157.162",
          ),
        ),
        // Add more providers here if needed
      ],
      child: const MainApp(),
    ),
  );
}

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
