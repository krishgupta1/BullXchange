import 'package:flutter/material.dart';

class LogoContainer extends StatelessWidget {
  final String name;
  final double radius;

  const LogoContainer({super.key, required this.name, this.radius = 25});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
