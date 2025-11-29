import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';

class IndexCard extends StatelessWidget {
  final Instrument? instrument;
  final String? title; // Optional title override

  const IndexCard({super.key, required this.instrument, this.title});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme Data ---
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
    final isNegative = changeValue.isNegative;

    // Colors & Icon logic
    final changeColor = isNegative ? Colors.redAccent : const Color(0xFF00C853);
    final trendIcon = isNegative
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;

    final changeText = "$netChange ($percentChange%)";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Title + Trend Icon Background
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: textTheme.bodySmall?.copyWith(
                    color: textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(trendIcon, size: 16, color: changeColor),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Price Text
          Text(
            value != "0.00" ? "₹$value" : "...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          // Change Percentage Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              changeText,
              style: textTheme.bodySmall?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
