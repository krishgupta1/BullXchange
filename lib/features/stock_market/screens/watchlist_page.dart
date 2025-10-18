import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// --- Mock Data for User's Watchlist ---
// In a real app, this list of tokens would be saved in user preferences.
final List<String> userWatchlistTokens = [
  '547', // AXISBANK-EQ
  '13538', // SPUL-EQ
  '11723', // IGL-EQ
  '1727', // KRBL-EQ
  '10184', // INDIAMART-EQ
  '3456', // TATASTEEL-EQ
];

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // --- Data Processing ---
        final watchlistStocks = provider.allNSEStocks
            .where((stock) => userWatchlistTokens.contains(stock.token))
            .toList();

        // Handle case where the watchlist is empty
        if (watchlistStocks.isEmpty) {
          return const _EmptyState();
        }

        // ✨ FIX: Use a Column to prevent nested scrolling errors.
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- Header with stock count and actions ---
                  _buildWatchlistHeader(watchlistStocks.length),
                  const SizedBox(height: 16),
                  // --- Sort controls ---
                  _buildSortHeader(),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // --- Watchlist stocks ---
            ...watchlistStocks.map((instrument) {
              return _buildStockItem(instrument: instrument);
            }),
          ],
        );
      },
    );
  }
}

// --- Reusable Widgets ---

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 20),
        Icon(
          Icons.star_border_purple500_outlined,
          size: 48,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Text(
          "Your Watchlist is Empty",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Add stocks to your watchlist to track them easily.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget _buildWatchlistHeader(int stockCount) {
  return Row(
    children: [
      Text(
        "$stockCount stocks",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: () {}),
      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
    ],
  );
}

Widget _buildSortHeader() {
  return Row(
    children: [
      TextButton.icon(
        icon: const Icon(Icons.sort, color: Colors.black54),
        label: const Text("Sort", style: TextStyle(color: Colors.black54)),
        onPressed: () {},
      ),
      const Spacer(),
      Text(
        "Mkt price / 1D <>",
        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
      ),
    ],
  );
}

Widget _buildStockItem({required Instrument instrument}) {
  final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final changeColor = netChange >= 0 ? Colors.green : Colors.red;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      children: [
        _buildLogoContainer(instrument.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instrument.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                instrument.name,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 30,
          child: _buildMiniChart(instrument, changeColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₹${ltp.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "(${netChange.toStringAsFixed(2)})",
              style: TextStyle(color: changeColor, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildLogoContainer(String name) {
  if (name.toLowerCase().contains('google'))
    return SvgPicture.network(
      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
      width: 40,
      height: 40,
    );
  if (name.toLowerCase().contains('microsoft'))
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/240px-Microsoft_logo.svg.png',
      width: 40,
      height: 40,
    );

  final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
  final color = Colors.primaries[name.hashCode % Colors.primaries.length];
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildMiniChart(Instrument instrument, Color color) {
  final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  if (ltp == 0.0) return Container();

  final startPrice = ltp - netChange;
  final points = <FlSpot>[];
  final random = Random(instrument.symbol.hashCode);

  for (int i = 0; i < 15; i++) {
    if (i == 14) {
      points.add(FlSpot(i.toDouble(), ltp));
    } else {
      double progress = i / 14.0;
      double priceAtProgress = startPrice + (netChange * progress);
      double variance = ltp * 0.01 * (random.nextDouble() - 0.5);
      points.add(FlSpot(i.toDouble(), priceAtProgress + variance));
    }
  }

  return LineChart(
    LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: points,
          isCurved: true,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    ),
  );
}
