// lib/shared/widgets/main_page_header.dart

import 'package:flutter/material.dart';

class MainPageHeader extends StatelessWidget {
  final String? userName;
  final String defaultUserName;
  final String welcomeMessage;
  final List<Widget> actions;

  const MainPageHeader({
    super.key,
    required this.userName,
    this.defaultUserName = 'User', // A sensible overall default
    required this.welcomeMessage,
    this.actions = const [], // Default to an empty list
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFEAE2FF),
          child: Icon(Icons.person, color: Color(0xFF7A4DFF), size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${userName ?? defaultUserName}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              welcomeMessage,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        // This will add all widgets from the 'actions' list
        ...actions,
      ],
    );
  }
}
