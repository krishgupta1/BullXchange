// lib/provider/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. THEME CONTROLLER (Yeh save/load karega) ---
// (Yeh aapka code hai, yeh bilkul sahi hai)
class ThemeNotifier extends ChangeNotifier {
  final SharedPreferences prefs;
  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  ThemeNotifier({required this.prefs}) {
    _loadTheme();
  }

  void _loadTheme() {
    // Disk se 'themeMode' string nikalo
    final String themeName = prefs.getString('themeMode') ?? 'system';

    // String (e.g., "dark") ko wapas ThemeMode (e.g., ThemeMode.dark) mein badlo
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeMode.system, // Agar kuch na mile toh 'system' default
    );
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;

      // --- SAVE TO DISK ---
      prefs.setString('themeMode', mode.name);

      // --- UPDATE UI ---
      notifyListeners();
    }
  }
}
