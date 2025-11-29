import 'package:flutter/material.dart';

/// A custom widget to display a Live Traded Price (LTP)
/// and its change (either absolute or percentage).
///
/// The change will be colored green for positive/zero values
/// and red for negative values.
class LtpChangeWidget extends StatelessWidget {
  /// The live traded price, displayed as a string (e.g., "123.45").
  final String ltp;

  /// The numeric value of the change.
  final double change;

  /// If true, displays the change as a percentage (e.g., "+1.50%").
  /// If false, displays it as an absolute value (e.g., "+1.50").
  final bool isPercent;

  const LtpChangeWidget({
    super.key,
    required this.ltp,
    required this.change,
    this.isPercent = false,
    required String customPercentString, // Defaults to showing absolute change
  });

  @override
  Widget build(BuildContext context) {
    // Determine the color based on the change value
    final Color changeColor = change.isNegative ? Colors.red : Colors.green;

    // Format the change text
    String changeText;
    final String prefix = change.isNegative ? '' : '+';

    if (isPercent) {
      changeText = '$prefix${change.toStringAsFixed(2)}%';
    } else {
      changeText = '$prefix${change.toStringAsFixed(2)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end, // Align text to the right
      mainAxisAlignment:
          MainAxisAlignment.center, // Center vertically in ListTile
      children: [
        Text(
          ltp,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          changeText,
          style: TextStyle(
            color: changeColor,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
