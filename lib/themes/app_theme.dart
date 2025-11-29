import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORS ---
  static const Color kPrimaryBlue = Color(0xFF4318FF);
  static const Color kBrandPink = Color(0xFFDB1B57);
  static const Color kSecondaryGrey = Colors.grey;
  static const Color kButtonPurple = Color(0xFFC7B8F5);

  // --- TYPOGRAPHY CONSTANTS ---
  static const String _fontFamily = 'EudoxusSans';
  static const double _appBarFontSize = 22;
  static const double _h1FontSize = 21;
  static const double _h2FontSize = 18;
  static const double _bodyFontSize = 16;
  static const double _captionFontSize = 14;

  // --- LIGHT TEXT THEME ---
  static final TextTheme _lightTextTheme = TextTheme(
    displayLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: kPrimaryBlue,
    ),
    displayMedium: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kPrimaryBlue,
    ),
    headlineSmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _h1FontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _h2FontSize,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    titleMedium: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _bodyFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    titleSmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _captionFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    bodyLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _bodyFontSize,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
    bodyMedium: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _captionFontSize,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
    ),
    bodySmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: Colors.grey,
    ),
    labelLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _bodyFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    labelSmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _captionFontSize,
      fontWeight: FontWeight.normal,
      color: Colors.grey,
    ),
  );

  // --- DARK TEXT THEME ---
  static final TextTheme _darkTextTheme = TextTheme(
    displayLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: kPrimaryBlue,
    ),
    displayMedium: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kPrimaryBlue,
    ),
    headlineSmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _h1FontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _h2FontSize,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleMedium: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _bodyFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleSmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _captionFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    ),
    bodyLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _bodyFontSize,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    bodyMedium: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _captionFontSize,
      fontWeight: FontWeight.normal,
      color: Colors.white70,
    ),
    bodySmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: Colors.grey,
    ),
    labelLarge: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _bodyFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    labelSmall: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: _captionFontSize,
      fontWeight: FontWeight.normal,
      color: Colors.grey,
    ),
  );

  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    shadowColor: Colors.grey.withOpacity(0.5),
    colorScheme: ColorScheme.light(
      primary: kPrimaryBlue,
      secondary: kBrandPink,
      surface: Colors.white,
      onSurface: Colors.black,
      secondaryContainer: kButtonPurple,
      onSecondaryContainer: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: kBrandPink),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: kPrimaryBlue,
        fontWeight: FontWeight.bold,
        fontSize: _appBarFontSize,
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
    textTheme: _lightTextTheme,
  );

  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: kBrandPink),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: _appBarFontSize,
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
    textTheme: _darkTextTheme,
  );
}
