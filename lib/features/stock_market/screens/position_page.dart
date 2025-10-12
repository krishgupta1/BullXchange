import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

// Using the same data structure for positions
final List<Map<String, dynamic>> positions = [
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

class PositionPage extends StatelessWidget {
  const PositionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      children: [
        // --- 1. Position Summary Card ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildPositionSummaryCard(),
        ),
        const SizedBox(height: 24),

        // --- 2. "Delivery" Section Header ---
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Delivery",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        // --- 3. Positions List ---
        ...positions.map((p) {
          return _buildStockItem(
            logo: _buildLogoContainer(
              p['logo'] == 'twitter' ? Colors.blue.shade700 : Colors.black,
              p['logo'].substring(0, 1).toUpperCase(),
              isGoogle: p['isGoogle'] ?? false,
              isMicrosoft: p['isMicrosoft'] ?? false,
            ),
            company: p['stockName'],
            shares: '${p['shares']} shares',
            price: p['price'],
            change: p['priceChange'],
            changeColor: p['trendColor'],
            data: p['data'],
          );
        }).toList(),
      ],
    );
  }
}

// --- Reusable Widgets ---

Widget _buildPositionSummaryCard() {
  return Container(
    // ✨ FIX 1: Set a fixed height to match the holdings page card.
    height: 170,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF6F4CFF), Color(0xFFDB1B57)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Returns Section
        Text(
          "Total returns",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text(
              "+₹799.97",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "+810%",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        // ✨ FIX 2: Add a Spacer to push the buttons to the bottom.
        const Spacer(),
        // Buttons Section
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Exit all"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton.icon(
                icon: const Text("Set safe exit"),
                label: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Unchanged from holdings_page.dart
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
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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

// Unchanged from holdings_page.dart
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
      placeholderBuilder: (BuildContext context) =>
          const CircularProgressIndicator(),
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

// Unchanged from holdings_page.dart
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
          spots: data.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value);
          }).toList(),
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
