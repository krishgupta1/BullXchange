import 'package:flutter/material.dart';

class AppTheme {
  static const Color kPrimaryBlue = Color(0xFF4318FF);
  static const Color kBrandPink = Color(0xFFDB1B57);
  static const Color kSecondaryGrey = Colors.grey;
  static const Color kButtonPurple = Color(0xFFC7B8F5);

  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'EudoxusSans',
    shadowColor: Colors.grey.withOpacity(0.5),
    colorScheme: ColorScheme.light(
      primary: kPrimaryBlue,
      secondary: kBrandPink,
      surface: Colors.white,
      onSurface: Colors.black,
      secondaryContainer: kButtonPurple,
      onSecondaryContainer: Colors.white,
      error: Colors.red,
      // --- ⭐️⭐️ FIX: Button text colors add kiye ---
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: kBrandPink),
      titleTextStyle: TextStyle(
        fontFamily: 'EudoxusSans',
        color: kPrimaryBlue,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return kBrandPink;
        }
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return kBrandPink.withOpacity(0.5);
        }
        return Colors.grey.shade200;
      }),
    ),
    textTheme: const TextTheme(bodySmall: TextStyle(color: kSecondaryGrey)),
  );

  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'EudoxusSans',
    scaffoldBackgroundColor: Colors.black,
    shadowColor: Colors.black.withOpacity(0.5),
    colorScheme: ColorScheme.dark(
      primary: kPrimaryBlue,
      secondary: kBrandPink,
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
      secondaryContainer: kButtonPurple,
      onSecondaryContainer: Colors.white,
      error: Colors.redAccent,
      // --- ⭐️⭐️ FIX: Button text colors add kiye ---
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: kBrandPink),
      titleTextStyle: TextStyle(
        fontFamily: 'EudoxusSans',
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return kBrandPink;
        }
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return kBrandPink.withOpacity(0.5);
        }
        return Colors.grey.shade800;
      }),
    ),
    textTheme: TextTheme(bodySmall: TextStyle(color: Colors.grey[400])),
  );
}
