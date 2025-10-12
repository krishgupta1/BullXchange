import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Data structure for open orders
final List<Map<String, dynamic>> openOrders = [
  {
    'logo': 'twitter',
    'stockName': 'Twitter Inc.',
    'marketPrice': '1750',
    'orderPrice': '1725',
    'quantity': 20,
    'trendColor': Colors.blue,
    'data': const [2.0, 3.0, 2.0, 4.0, 3.0, 5.0, 3.0],
  },
  {
    'logo': 'google',
    'isGoogle': true,
    'stockName': 'Alphabet Inc.',
    'marketPrice': '1750',
    'orderPrice': '1725',
    'quantity': 20,
    'trendColor': Colors.green,
    'data': const [2.0, 3.0, 5.0, 4.0, 6.0, 7.0, 8.0],
  },
  {
    'logo': 'microsoft',
    'isMicrosoft': true,
    'stockName': 'Microsoft',
    'marketPrice': '1750',
    'orderPrice': '1725',
    'quantity': 20,
    'trendColor': Colors.red,
    'data': const [5.0, 4.0, 6.0, 3.0, 5.0, 4.0, 2.0],
  },
  {
    'logo': 'nike',
    'stockName': 'Nike, Inc.',
    'marketPrice': '1750',
    'orderPrice': '1725',
    'quantity': 20,
    'trendColor': Colors.orange,
    'data': const [4.0, 5.0, 3.0, 4.0, 2.0, 3.0, 1.0],
  },
];

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Header with collapsible icon ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Open orders (${openOrders.length})",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.keyboard_arrow_up),
          ],
        ),
        const SizedBox(height: 16),
        // --- Cancel all / Qty Header ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(
                Icons.cancel_outlined,
                color: Colors.grey,
                size: 20,
              ),
              label: Text(
                "Cancel all",
                style: TextStyle(color: Colors.grey[700]),
              ),
              onPressed: () {},
            ),
            Text(
              "Qty/Price",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // --- Orders List ---
        ...openOrders.map((order) {
          return _buildOrderItem(
            logo: _buildLogoContainer(
              order['logo'] == 'twitter' ? Colors.blue.shade700 : Colors.black,
              order['logo'].substring(0, 1).toUpperCase(),
              isGoogle: order['isGoogle'] ?? false,
              isMicrosoft: order['isMicrosoft'] ?? false,
            ),
            stockName: order['stockName'],
            marketPrice: order['marketPrice'],
            orderPrice: order['orderPrice'],
            quantity: order['quantity'],
            data: order['data'],
            color: order['trendColor'],
          );
        }).toList(),
      ],
    );
  }
}

// --- Reusable Widgets ---

Widget _buildOrderItem({
  required Widget logo,
  required String stockName,
  required String marketPrice,
  required String orderPrice,
  required int quantity,
  required List<double> data,
  required Color color,
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
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: "BUY + ",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: "SL/TGT",
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stockName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Mkt ₹$marketPrice",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(width: 60, height: 30, child: _buildMiniChart(data, color)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Intraday",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              "$quantity",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              "At ₹$orderPrice",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
