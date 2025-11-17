// lib/shared/widgets/main_page_header.dart

import 'package:flutter/material.dart';

class MainPageHeader extends StatelessWidget {
  final String? userName;
  final String defaultUserName;
  final String welcomeMessage;
  final List<Widget> actions;
  final VoidCallback? onProfileTap; // <-- ⭐️ 1. ADDED THIS CALLBACK

  const MainPageHeader({
    super.key,
    required this.userName,
    this.defaultUserName = 'User', // A sensible overall default
    required this.welcomeMessage,
    this.actions = const [], // Default to an empty list
    this.onProfileTap, // <-- ⭐️ 2. ADDED TO CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ 3. GET THEME COLORS ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: [
        // --- ⭐️ 4. WRAPPED AVATAR IN GESTUREDETECTOR ---
        GestureDetector(
          onTap: onProfileTap, // <-- 5. USED THE CALLBACK
          child: CircleAvatar(
            radius: 24,
            // --- ⭐️ 6. MADE COLORS THEME-AWARE ---
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.person, color: colorScheme.primary, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${userName ?? defaultUserName}!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // --- ⭐️ 7. MADE TEXT THEME-AWARE ---
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              welcomeMessage,
              style: TextStyle(
                fontSize: 14,
                // --- ⭐️ 8. MADE TEXT THEME-AWARE ---
                color: textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        const Spacer(),
        // This will add all widgets from the 'actions' list
        ...actions,
      ],
    );
  }
}
