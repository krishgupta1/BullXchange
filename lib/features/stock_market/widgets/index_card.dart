import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';

class IndexCard extends StatelessWidget {
  final Instrument? instrument;
  final String? title; // Optional title override

  const IndexCard({super.key, required this.instrument, this.title});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- Data Logic (Unchanged) ---
    final name =
        title ?? // Use the override title if provided
        instrument?.name.toUpperCase().replaceFirst("NIFTY ", "") ??
        "LOADING...";
    final value = instrument?.liveData["ltp"]?.toStringAsFixed(2) ?? "0.00";
    final netChange =
        instrument?.liveData["netChange"]?.toStringAsFixed(2) ?? "0.00";
    final percentChange =
        instrument?.liveData["percentChange"]?.toStringAsFixed(2) ?? "0.00";

    final double changeValue = num.tryParse(netChange)?.toDouble() ?? 0.0;
    // Green/Red colors same rehte hain
    final changeColor = changeValue.isNegative ? Colors.red : Colors.green;

    final changeText = "$netChange($percentChange%)";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme se background color ---
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // --- ⭐️ MODIFIED: Theme se shadow color ---
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              // --- ⭐️ MODIFIED: Theme se grey text color ---
              color: textTheme.bodySmall?.color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value != "0.00" ? "₹$value" : "...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // --- ⭐️ MODIFIED: Theme se main text color ---
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              color: changeColor, // Green/Red
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
