import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/app_typography.dart';

/// Reusable UI components for consistent design across the app.
/// Reduces code duplication and improves maintenance.

class AppComponents {
  // --- SECTION HEADER WITH OPTIONAL ACTION ---
  /// Reusable header for list sections with optional trailing button
  static Widget sectionHeader(
    BuildContext context, {
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppTypography.heading2(context, title),
          if (actionText != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: AppTypography.bodySmallText(context, actionText),
            ),
        ],
      ),
    );
  }

  // --- INFO CARD (Wallet, Holdings, etc.) ---
  /// Reusable card for displaying key financial information
  static Widget infoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconColor,
              child: Icon(icon, color: colorScheme.surface, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTypography.bodySmallText(context, label),
                  const SizedBox(height: 4),
                  AppTypography.heading2(context, value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MENU ITEM ---
  /// Reusable menu item with icon, title, and optional trailing widget
  static Widget menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: AppTypography.bodyText(context, title)),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  color: textTheme.bodySmall?.color,
                  size: 14,
                ),
          ],
        ),
      ),
    );
  }

  // --- STAT ROW (for portfolio, holdings, etc.) ---
  /// Reusable row for displaying stat label and value
  static Widget statRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppTypography.bodySmallText(context, label),
          AppTypography.customText(
            context,
            value,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
            fontSize: isHighlight ? 14 : 13,
          ),
        ],
      ),
    );
  }

  // --- LOADING CARD SKELETON ---
  /// Reusable skeleton loader for data cards
  static Widget skeletonLoader({
    double height = 80,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: borderRadius,
      ),
    );
  }

  // --- DIVIDER WITH PADDING ---
  /// Reusable divider with consistent spacing
  static Widget spacedDivider({
    double horizontalPadding = 16,
    double verticalSpacing = 12,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalSpacing,
      ),
      child: Divider(
        thickness: 1,
        height: 1,
        color: Colors.grey.withOpacity(0.1),
      ),
    );
  }
}
