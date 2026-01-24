import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsets padding;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize = 18,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: iconColor ?? colorScheme.onSurface,
            size: iconSize,
          ),
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
