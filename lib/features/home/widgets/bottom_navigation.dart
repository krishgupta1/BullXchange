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
    // ✨ FIX: Define the selected color to match the screenshot
    const Color selectedColor = Color(0xFF3500D4);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      // Use the new selected color for the text
      selectedItemColor: selectedColor,
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      // Remove the default icon size to have more control
      iconSize: 24,
      items: [
        // ✨ FIX: Use the `activeIcon` property for a custom selected state
        BottomNavigationBarItem(
          icon: const Icon(Icons.ssid_chart),
          activeIcon: _buildActiveIcon(Icons.ssid_chart, selectedColor),
          label: 'Stocks',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.widgets_outlined),
          activeIcon: _buildActiveIcon(Icons.widgets_outlined, selectedColor),
          label: 'F&O',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.pie_chart_outline),
          activeIcon: _buildActiveIcon(Icons.pie_chart, selectedColor),
          label: 'Portfolio',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.auto_awesome_outlined),
          activeIcon: _buildActiveIcon(Icons.auto_awesome, selectedColor),
          label: 'AI Stats',
        ),
      ],
    );
  }
}

/// Helper widget to create the blue container for the active icon
Widget _buildActiveIcon(IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(5.0),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Icon(icon, color: Colors.white),
  );
}
