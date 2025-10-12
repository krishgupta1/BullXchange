import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

// --- Updated Data Structure ---
// ✨ FIX: Chart data is now a List<double> to prevent type errors.
final List<Map<String, dynamic>> holdings = [
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
    'isGoogle': true, // Flag for SVG logo
    'stockName': 'Alphabet Inc.',
    'shares': 5,
    'price': '₹1,720.98',
    'priceChange': '₹1,540.90',
    'trendColor': Colors.green,
    'data': const [2.0, 3.0, 5.0, 4.0, 6.0, 7.0, 8.0],
  },
  {
    'logo': 'microsoft',
    'isMicrosoft': true, // Flag for PNG logo
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

class HoldingsPage extends StatelessWidget {
  const HoldingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      children: [
        // --- 1. Summary Card ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSummaryCard(),
        ),
        const SizedBox(height: 24),

        // --- 2. Holdings List ---
        ...holdings.map((h) {
          return _buildStockItem(
            logo: _buildLogoContainer(
              h['logo'] == 'twitter' ? Colors.blue.shade700 : Colors.black,
              h['logo'].substring(0, 1).toUpperCase(),
              isGoogle: h['isGoogle'] ?? false,
              isMicrosoft: h['isMicrosoft'] ?? false,
            ),
            company: h['stockName'],
            shares: '${h['shares']} shares',
            price: h['price'],
            change: h['priceChange'],
            changeColor: h['trendColor'],
            data: h['data'],
          );
        }).toList(),
      ],
    );
  }
}

// --- Reusable Widgets ---

Widget _buildSummaryCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    height: 170,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF6F4CFF), Color(0xFFDB1B57)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryColumn("Current", "₹9,863.09"),
            _buildSummaryColumn("Total returns", "+₹799.97", isReturn: true),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryColumn("Invested", "₹9,063.12"),
            _buildSummaryColumn("1D returns", "+₹159.97", isReturn: true),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSummaryColumn(
  String title,
  String value, {
  bool isReturn = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isReturn) ...[
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
        ],
      ),
    ],
  );
}

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
    // ✨ FIX: Use Image.network for PNG files, not SvgPicture.network
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
