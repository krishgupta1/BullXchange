import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDarkMode = theme.brightness == Brightness.dark;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onItemTapped,

      // Background & Visibility
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      elevation: 8,

      // Colors
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: isDarkMode
          ? Colors.grey.shade400
          : Colors.grey.shade600,

      // Sizing
      selectedFontSize: 14,
      unselectedFontSize: 14,
      iconSize: 28,

      // --- ⭐️ ADDED: Font Weight 500 ---
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),

      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.ssid_chart),
          activeIcon: Icon(Icons.ssid_chart, color: colorScheme.primary),
          label: 'Stocks',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.widgets_outlined),
          activeIcon: Icon(Icons.widgets_outlined, color: colorScheme.primary),
          label: 'F&O',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.pie_chart_outline),
          activeIcon: Icon(Icons.pie_chart, color: colorScheme.primary),
          label: 'Portfolio',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.auto_awesome_outlined),
          activeIcon: Icon(Icons.auto_awesome, color: colorScheme.primary),
          label: 'AI Stats',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person, color: colorScheme.primary),
          label: 'Account',
        ),
      ],
    );
  }
}
