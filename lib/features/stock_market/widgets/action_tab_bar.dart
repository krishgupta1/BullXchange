import 'package:flutter/material.dart';

class ActionTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const ActionTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme Data Access ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (index) {
          bool isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 200,
              ), // Added smooth transition
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                // Selected: Pink. Unselected: Theme Surface (White/DarkGrey)
                color: isSelected ? const Color(0xFFDB1B57) : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        // Adaptive border color
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  // Selected: White. Unselected: Theme Text Color (Black/White)
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

