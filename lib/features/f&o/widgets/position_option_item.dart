import 'package:bullxchange/features/f&o/widgets/share_pnl_card.dart';
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PositionOptionItem extends StatelessWidget {
  final OptionHoldingModel position;

  const PositionOptionItem({super.key, required this.position});

  void _showShareCard(BuildContext context) {
    // Calculate P&L
    final totalVal = position.currentLtp * position.quantity;
    final invested = position.investedAmount;
    final pnl = totalVal - invested;
    final roi = (pnl / invested) * 100;

    showDialog(
      context: context,
      builder: (context) => SharePnlCard(
        symbol: position.contractSymbol,
        pnl: pnl,
        roi: roi,
        entryPrice: position.averagePrice,
        lastPrice: position.currentLtp,
        isIntraday: false, // It's an Option
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    // Calculations
    final currentVal = position.currentLtp * position.quantity;
    final invested = position.investedAmount;
    final pnl = currentVal - invested;
    final roi = (invested > 0) ? (pnl / invested) * 100 : 0.0;
    
    final isProfit = pnl >= 0;
    final pnlColor = isProfit 
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF00C853)) 
        : (isDark ? const Color(0xFFEF5350) : const Color(0xFFFF3D00));

    return InkWell(
      onTap: () => _showShareCard(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            // Logo Badge (CE/PE)
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (position.optionType == "CE" ? Colors.green : Colors.red).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(position.optionType, style: TextStyle(color: position.optionType == "CE" ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position.contractSymbol,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(context, "F&O"),
                      const SizedBox(width: 6),
                      Text(
                        "${(position.quantity / position.lotSize).toStringAsFixed(0)} Lots (${position.quantity})",
                        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Numbers
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatter.format(currentVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  "${isProfit ? '+' : ''}${formatter.format(pnl)} (${roi.toStringAsFixed(2)}%)",
                  style: TextStyle(color: pnlColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color)),
    );
  }
}