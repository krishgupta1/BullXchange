import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Using the same data structure for the watchlist
final List<Map<String, dynamic>> watchlistStocks = [
  {
    'logo': 'twitter',
    'stockName': 'Twitter Inc.',
    'shares': 5,
    'price': '₹1,720.98',
    'priceChange': '₹1,540.90',
    'trendColor': Colors.blue,
    'data': const [2.0, 3.0, 2.0, 4.0, 3.0, 5.0, 3.0],
  },
  {
    'logo': 'google',
    'isGoogle': true,
    'stockName': 'Alphabet Inc.',
    'shares': 5,
    'price': '₹1,720.98',
    'priceChange': '₹1,540.90',
    'trendColor': Colors.green,
    'data': const [2.0, 3.0, 5.0, 4.0, 6.0, 7.0, 8.0],
  },
  {
    'logo': 'microsoft',
    'isMicrosoft': true,
    'stockName': 'Microsoft',
    'shares': 5,
    'price': '₹1,720.98',
    'priceChange': '₹1,598.23',
    'trendColor': Colors.green,
    'data': const [5.0, 4.0, 6.0, 3.0, 5.0, 4.0, 2.0],
  },
  {
    'logo': 'nike',
    'stockName': 'Nike, Inc.',
    'shares': 5,
    'price': '₹1,720.98',
    'priceChange': '₹1,342.76',
    'trendColor': Colors.orange,
    'data': const [4.0, 5.0, 3.0, 4.0, 2.0, 3.0, 1.0],
  },
];

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Header with stock count and actions ---
        _buildWatchlistHeader(),
        const SizedBox(height: 16),
        // --- Sort controls ---
        _buildSortHeader(),
        const Divider(height: 24),

        // --- Watchlist stocks (reuses _buildStockItem) ---
        ...watchlistStocks.map((stock) {
          return _buildStockItem(
            logo: _buildLogoContainer(
              stock['logo'] == 'twitter' ? Colors.blue.shade700 : Colors.black,
              stock['logo'].substring(0, 1).toUpperCase(),
              isGoogle: stock['isGoogle'] ?? false,
              isMicrosoft: stock['isMicrosoft'] ?? false,
            ),
            company: stock['stockName'],
            shares: '${stock['shares']} shares',
            price: stock['price'],
            change: stock['priceChange'],
            changeColor: stock['trendColor'],
            data: stock['data'],
          );
        }),
      ],
    );
  }
}

// --- Reusable Widgets ---

Widget _buildWatchlistHeader() {
  return Row(
    children: [
      Text(
        "${watchlistStocks.length} stocks",
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
        "<> Mkt price / 1D",
        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
      ),
    ],
  );
}

// Copied from holdings_page.dart (it's a perfect match)
Widget _buildStockItem({
  required Widget logo,
  required String company,
  required String shares,
  required String price,
  required String change,
  required Color changeColor,
  required List<double> data,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Row(
      children: [
        logo,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                shares,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 30,
          child: _buildMiniChart(data, changeColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "($change)",
              style: TextStyle(color: changeColor, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

// Copied from previous pages
Widget _buildLogoContainer(
  Color bgColor,
  String letter, {
  bool isGoogle = false,
  bool isMicrosoft = false,
}) {
  if (isGoogle) {
    return SvgPicture.network(
      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
      width: 40,
      height: 40,
    );
  }
  if (isMicrosoft) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/240px-Microsoft_logo.svg.png',
      width: 40,
      height: 40,
    );
  }
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
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

// Copied from previous pages
Widget _buildMiniChart(List<double> data, Color color) {
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
          spots: data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList(),
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
