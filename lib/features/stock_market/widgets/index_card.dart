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
    
    // --- Responsive calculations ---
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final scaleFactor = screenWidth < 600 ? 1.0 : screenWidth < 1200 ? 1.1 : 1.2;
    
    // Helper function for scaling sizes
    double scaleSize(double size) {
      final scaled = size * (screenWidth / 375.0);
      return scaled.clamp(size * 0.8, size * 1.5);
    }
    
    double scaleFontSize(double fontSize) {
      final scaled = fontSize * scaleFactor;
      return scaled.clamp(fontSize * 0.95, fontSize * 1.2);
    }

    // --- Data Logic with Better Error Handling ---
    final name = title ?? // Use the override title if provided
        instrument?.name.toUpperCase().replaceFirst("NIFTY ", "") ??
        "LOADING...";
    
    // Better data parsing with fallbacks
    double ltpValue = 0.0;
    double netChangeValue = 0.0;
    double percentChangeValue = 0.0;
    
    if (instrument?.liveData != null) {
      ltpValue = (instrument?.liveData["ltp"] as num?)?.toDouble() ?? 0.0;
      netChangeValue = (instrument?.liveData["netChange"] as num?)?.toDouble() ?? 0.0;
      percentChangeValue = (instrument?.liveData["percentChange"] as num?)?.toDouble() ?? 0.0;
    }
    
    // Format values with proper fallbacks
    final value = ltpValue > 0 ? ltpValue.toStringAsFixed(2) : "--.--";
    final netChange = netChangeValue != 0 ? netChangeValue.toStringAsFixed(2) : "0.00";
    final percentChange = percentChangeValue != 0 ? percentChangeValue.toStringAsFixed(2) : "0.00";

    final isNegative = netChangeValue < 0;
    final hasData = ltpValue > 0;

    // Colors & Icon logic with better states
    final changeColor = !hasData 
        ? Colors.grey 
        : (isNegative ? Colors.redAccent : const Color(0xFF00C853));
    final trendIcon = !hasData
        ? Icons.help_outline_rounded
        : (isNegative ? Icons.trending_down_rounded : Icons.trending_up_rounded);

    final changeText = hasData 
        ? "$netChange ($percentChange%)"
        : "No Data";

    return Container(
      padding: EdgeInsets.all(scaleSize(20.0)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(scaleSize(20.0)),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            spreadRadius: 0,
            blurRadius: scaleSize(20.0) * 0.6,
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
                    color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.all(scaleSize(4.0) * 1.5),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(trendIcon, size: scaleSize(24.0) * 0.7, color: changeColor),
              ),
            ],
          ),

          SizedBox(height: scaleSize(8.0)),

          // Main Price Text
          Text(
            hasData ? "₹$value" : "₹--.--",
            style: TextStyle(
              fontSize: scaleFontSize(18.0) * 0.85, // Reduced font size
              fontWeight: FontWeight.w800,
              color: hasData ? colorScheme.onSurface : Colors.grey,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: scaleSize(4.0) * 1.5),

          // Change Percentage Text
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: scaleSize(4.0) * 1.5, // Reduced padding
              vertical: scaleSize(4.0) * 0.8,
            ),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(scaleSize(20.0) * 0.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trendIcon,
                  size: scaleSize(24.0) * 0.4, // Smaller icon
                  color: changeColor,
                ),
                SizedBox(width: scaleSize(4.0) * 0.3), // Reduced spacing
                Flexible(
                  child: Text(
                    changeText,
                    style: textTheme.bodySmall?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: scaleFontSize(10.0) * 0.9, // Smaller font
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
