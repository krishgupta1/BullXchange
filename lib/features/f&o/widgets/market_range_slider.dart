import 'package:flutter/material.dart';

class MarketRangeSlider extends StatelessWidget {
  final double low;
  final double high;
  final double current;

  const MarketRangeSlider({
    super.key,
    required this.low,
    required this.high,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    if (low == 0 || high == 0 || current == 0) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    // Calculate percentage (0.0 to 1.0)
    double percentage = (current - low) / (high - low);
    percentage = percentage.clamp(0.0, 1.0);

    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double leftPos = (constraints.maxWidth * percentage) - 6;
          // Keep icon inside bounds
          final double safeLeft = leftPos.clamp(0.0, constraints.maxWidth - 12);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // The Grey Bar
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // The White Triangle Indicator
              Positioned(
                left: safeLeft,
                child: const Icon(
                  Icons.arrow_drop_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
