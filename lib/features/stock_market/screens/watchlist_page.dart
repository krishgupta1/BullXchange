import 'package:flutter/material.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.travel_explore, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Watchlist Page Content',
              style: TextStyle(fontSize: 22, color: Colors.grey),
            ),
            Text(
              'Top Stocks, Market Movers, and more will be shown here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
