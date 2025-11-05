import 'package:flutter/material.dart';

class FutureOptionWatchlistPage extends StatelessWidget {
  const FutureOptionWatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    // DO NOT return a Scaffold here.
    // Just return the body content for the tab.
    return const Column(
      children: [
        SizedBox(height: 20),
        Center(
          child: Text('Watchlist Future Options Here'),
        ),
        // You can add more widgets here, like your "Top Traded" list
      ],
    );
  }
}