import 'package:flutter/material.dart';

class FutureOptionExplorePage extends StatelessWidget {
  const FutureOptionExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // DO NOT return a Scaffold here.
    // Just return the body content for the tab.
    return const Column(
      children: [
        SizedBox(height: 20),
        Center(
          child: Text('Explore Future Options Here'),
        ),
        // You can add more widgets here, like your "Top Traded" list
      ],
    );
  }
}