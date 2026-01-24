// lib/shared/widgets/main_page_header.dart

import 'package:flutter/material.dart';
import 'package:bullxchange/utils/responsive_helper.dart';

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
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.tinySpacing, 
        horizontal: ResponsiveHelper.tinySpacing
      ),
      child: Row(
        children: [
          // --- ⭐️ MODERN AVATAR ---
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: ResponsiveHelper.avatarSize,
              height: ResponsiveHelper.avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                // Subtle border ring
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                // Soft shadow for depth
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: ResponsiveHelper.cardBorderRadius * 0.5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Material(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  child: InkWell(
                    onTap: onProfileTap,
                    child: Icon(
                      Icons.person_rounded, // Rounded icon looks more modern
                      color: colorScheme.primary,
                      size: ResponsiveHelper.iconSize * 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: ResponsiveHelper.smallSpacing),

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
                    fontSize: ResponsiveHelper.h2FontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveHelper.tinySpacing),
                Text(
                  welcomeMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: ResponsiveHelper.tinySpacing),

          // --- ⭐️ ACTIONS ---
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}
