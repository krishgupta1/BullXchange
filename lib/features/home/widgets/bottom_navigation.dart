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
    // --- Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Selected color (Dark Blue) theme se aa raha hai
    final Color selectedColor = colorScheme.primary;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onItemTapped,

      selectedItemColor: selectedColor,
      unselectedItemColor: textTheme.bodySmall?.color, // Grey
      // Background color theme_provider.dart se aa raha hai
      // (Light mein white, Dark mein dark grey)
      selectedFontSize: 12,
      unselectedFontSize: 12,
      iconSize: 24,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.ssid_chart),
          // --- ⭐️ MODIFIED: Sirf icon pass kiya ---
          activeIcon: Icon(Icons.ssid_chart, color: selectedColor),
          label: 'Stocks',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.widgets_outlined),
          // --- ⭐️ MODIFIED: Sirf icon pass kiya ---
          activeIcon: Icon(Icons.widgets_outlined, color: selectedColor),
          label: 'F&O',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.pie_chart_outline),
          // --- ⭐️ MODIFIED: Sirf icon pass kiya ---
          activeIcon: Icon(Icons.pie_chart, color: selectedColor),
          label: 'Portfolio',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.auto_awesome_outlined),
          // --- ⭐️ MODIFIED: Sirf icon pass kiya ---
          activeIcon: Icon(Icons.auto_awesome, color: selectedColor),
          label: 'AI Stats',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          // --- ⭐️ MODIFIED: Sirf icon pass kiya ---
          activeIcon: Icon(Icons.person, color: selectedColor),
          label: 'Account',
        ),
      ],
    );
  }
}

// --- ⭐️ REMOVED: _buildActiveIcon helper function ---
