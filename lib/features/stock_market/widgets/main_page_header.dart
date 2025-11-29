// lib/shared/widgets/main_page_header.dart

import 'package:flutter/material.dart';

class MainPageHeader extends StatelessWidget {
  final String? userName;
  final String defaultUserName;
  final String welcomeMessage;
  final List<Widget> actions;
  final VoidCallback? onProfileTap;

  const MainPageHeader({
    super.key,
    required this.userName,
    this.defaultUserName = 'User',
    required this.welcomeMessage,
    this.actions = const [],
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          // --- ⭐️ MODERN AVATAR ---
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                // Subtle border ring
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.15),
                  width: 1.5,
                ),
                // Soft shadow for depth
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Material(
                  color: colorScheme.primary.withOpacity(0.08),
                  child: InkWell(
                    onTap: onProfileTap,
                    child: Icon(
                      Icons.person_rounded, // Rounded icon looks more modern
                      color: colorScheme.primary,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // --- ⭐️ TYPOGRAPHY & LAYOUT ---
          // Using Expanded ensures text truncates properly on small screens
          // and acts like a Spacer to push actions to the right.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi, ${userName ?? defaultUserName}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  welcomeMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // --- ⭐️ ACTIONS ---
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}


