import 'package:flutter/material.dart';

class TradeActionButtons extends StatelessWidget {
  final VoidCallback onSell;
  final VoidCallback onBuy;
  final String sellLabel;
  final String buyLabel;
  final double height;

  const TradeActionButtons({
    super.key,
    required this.onSell,
    required this.onBuy,
    this.sellLabel = 'Sell',
    this.buyLabel = 'Buy',
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onSell,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shadowColor: colorScheme.primary.withOpacity(0.4),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                sellLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                shadowColor: colorScheme.secondary.withOpacity(0.4),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buyLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
