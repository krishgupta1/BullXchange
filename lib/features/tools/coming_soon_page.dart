import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:flutter/material.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme; // 🔥 FIXED ERROR
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'Coming Soon',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface, // 🔥 Now works correctly
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Text(
          "Coming Soon ❤️",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark
                ? Colors.white.withOpacity(0.9)
                : Colors.black.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}
