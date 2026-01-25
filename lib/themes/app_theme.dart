import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORS ---
  static const Color kPrimaryBlue = Color(0xFF4318FF);
  static const Color kBrandPink = Color(0xFFDB1B57);
  static const Color kSecondaryGrey = Colors.grey;
  static const Color kButtonPurple = Color(0xFFC7B8F5);

  // --- TYPOGRAPHY CONSTANTS (Updated to use ResponsiveHelper) ---
  static const String _fontFamily = 'EudoxusSans';
  
  // Font sizes will now be dynamically calculated using ResponsiveHelper
  // This ensures consistency across all screen sizes

  // --- MODERN LIGHT TEXT THEME ---
  static TextTheme getLightTextTheme(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final scaleFactor = screenWidth < 600 ? 1.0 : screenWidth < 1200 ? 1.1 : 1.2;
    
    // Helper function for scaling font sizes
    double scaleFontSize(double fontSize) {
      final scaled = fontSize * scaleFactor;
      return scaled.clamp(fontSize * 0.95, fontSize * 1.2);
    }
    
    return TextTheme(
      // Display styles (for hero sections, splash screens)
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(32.0),
        fontWeight: FontWeight.bold,
        color: kPrimaryBlue,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(28.0),
        fontWeight: FontWeight.bold,
        color: kPrimaryBlue,
        height: 1.2,
      ),
      
      // Headline styles (for section headers)
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(24.0),
        fontWeight: FontWeight.bold,
        color: Colors.black,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(20.0),
        fontWeight: FontWeight.w700,
        color: Colors.black,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(18.0),
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 1.3,
      ),
      
      // Title styles (for card titles, list items)
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(22.0),
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(16.0),
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(14.0),
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        height: 1.4,
      ),
      
      // Body styles (for content text)
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(16.0),
        fontWeight: FontWeight.w500,
        color: Colors.black,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(14.0),
        fontWeight: FontWeight.normal,
        color: Colors.black87,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(12.0),
        fontWeight: FontWeight.normal,
        color: Colors.grey,
        height: 1.4,
      ),
      
      // Label styles (for buttons, tags, captions)
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(16.0),
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(14.0),
        fontWeight: FontWeight.w500,
        color: Colors.black87,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(10.0),
        fontWeight: FontWeight.normal,
        color: Colors.grey,
        height: 1.3,
      ),
    );
  }

  // --- MODERN DARK TEXT THEME ---
  static TextTheme getDarkTextTheme(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final scaleFactor = screenWidth < 600 ? 1.0 : screenWidth < 1200 ? 1.1 : 1.2;
    
    // Helper function for scaling font sizes
    double scaleFontSize(double fontSize) {
      final scaled = fontSize * scaleFactor;
      return scaled.clamp(fontSize * 0.95, fontSize * 1.2);
    }
    
    return TextTheme(
      // Display styles (for hero sections, splash screens)
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(32.0),
        fontWeight: FontWeight.bold,
        color: kPrimaryBlue,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(28.0),
        fontWeight: FontWeight.bold,
        color: kPrimaryBlue,
        height: 1.2,
      ),
      
      // Headline styles (for section headers)
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(24.0),
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(20.0),
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(18.0),
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.3,
      ),
      
      // Title styles (for card titles, list items)
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(22.0),
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(16.0),
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(14.0),
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        height: 1.4,
      ),
      
      // Body styles (for content text)
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(16.0),
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(14.0),
        fontWeight: FontWeight.normal,
        color: Colors.white70,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(12.0),
        fontWeight: FontWeight.normal,
        color: Colors.grey,
        height: 1.4,
      ),
      
      // Label styles (for buttons, tags, captions)
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(16.0),
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(14.0),
        fontWeight: FontWeight.w500,
        color: Colors.white70,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: scaleFontSize(10.0),
        fontWeight: FontWeight.normal,
        color: Colors.grey,
        height: 1.3,
      ),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData getLightTheme(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final scaleFactor = screenWidth < 600 ? 1.0 : screenWidth < 1200 ? 1.1 : 1.2;
    
    // Helper function for scaling font sizes
    double scaleFontSize(double fontSize) {
      final scaled = fontSize * scaleFactor;
      return scaled.clamp(fontSize * 0.95, fontSize * 1.2);
    }
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      shadowColor: Colors.grey.withValues(alpha: 0.5),
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBrandPink),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: kPrimaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: scaleFontSize(28.0),
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
            return kBrandPink.withValues(alpha: 0.5);
          }
          return Colors.grey.shade200;
        }),
      ),
      textTheme: getLightTextTheme(context),
    );
  }

  // --- DARK THEME ---
  static ThemeData getDarkTheme(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final scaleFactor = screenWidth < 600 ? 1.0 : screenWidth < 1200 ? 1.1 : 1.2;
    
    // Helper function for scaling font sizes
    double scaleFontSize(double fontSize) {
      final scaled = fontSize * scaleFactor;
      return scaled.clamp(fontSize * 0.95, fontSize * 1.2);
    }
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      colorScheme: ColorScheme.dark(
        primary: kPrimaryBlue,
        secondary: kBrandPink,
        surface: Colors.black,
        onSurface: Colors.white,
        secondaryContainer: kButtonPurple,
        onSecondaryContainer: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBrandPink),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: kPrimaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: scaleFontSize(28.0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF121212),
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
            return kBrandPink.withValues(alpha: 0.5);
          }
          return Colors.grey.shade200;
        }),
      ),
      textTheme: getDarkTextTheme(context),
    );
  }

  // Convenience getters for backward compatibility
  static ThemeData getLightThemeCompat(BuildContext context) => getLightTheme(context);
  static ThemeData getDarkThemeCompat(BuildContext context) => getDarkTheme(context);
}