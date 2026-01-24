import 'package:flutter/material.dart';

class LogoContainer extends StatelessWidget {
  final String name;
  final double radius;

  const LogoContainer({super.key, required this.name, this.radius = 25});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    // Using MaterialColor to get shades for gradient
    final MaterialColor baseColor =
        Colors.primaries[name.hashCode % Colors.primaries.length];

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Modern Gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.shade300, // Light source top-left
            baseColor.shade800, // Shadow bottom-right
          ],
        ),
        // Soft Drop Shadow matching the color
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        // Subtle inner light border
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.85, // Slightly adjusted for visual balance
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 4.0,
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
