import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // You can build your detailed Explore UI here.
    // For now, it's a placeholder with some text and an icon.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader("Top Stocks"),
        // const SizedBox(height: 5),
        _buildStockList(),
        const SizedBox(height: 20),
        _buildSectionHeader("Tools"),
        const SizedBox(height: 20),
        _buildToolsGrid(),
      ],
    );
  }
}

Widget _buildSectionHeader(String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      if (title == "Top Stocks")
        TextButton(
          onPressed: () {},
          child: const Text(
            "View all",
            style: TextStyle(color: Color(0xFFDB1B57), fontSize: 14),
          ),
        ),
    ],
  );
}

Widget _buildStockList() {
  return Column(
    children: [
      _buildStockItem(
        logo: _buildLogoContainer(const Color(0xFF1DA1F2), 'T'), // Twitter Blue
        ticker: 'TWTR',
        company: 'Twitter Inc.',
        price: '63.98',
        change: '-0.23%',
        changeColor: Colors.red,
        data: const [1, 3, 2, 4, 3, 5, 2],
      ),
      _buildStockItem(
        logo: _buildLogoContainer(
          Colors.transparent,
          'G',
          isGoogle: true,
        ), // Google
        ticker: 'GOOGLE',
        company: 'Alphabet Inc.',
        price: '2.84K',
        change: '+0.58%',
        changeColor: Colors.green,
        data: const [2, 3, 5, 4, 6, 7, 8],
      ),
      _buildStockItem(
        logo: _buildLogoContainer(
          Colors.transparent,
          'M',
          isMicrosoft: true,
        ), // MSFT
        ticker: 'MSFT',
        company: 'Microsoft',
        price: '302.1',
        change: '-0.23%',
        changeColor: Colors.red,
        data: const [5, 4, 6, 3, 5, 4, 2],
      ),
      _buildStockItem(
        logo: _buildLogoContainer(Colors.black, 'N'), // Nike
        ticker: 'NIKE',
        company: 'Nike, Inc.',
        price: '169.8',
        change: '-0.082%',
        changeColor: Colors.red,
        data: const [4, 3, 2, 4, 3, 2, 1],
      ),
    ],
  );
}

Widget _buildLogoContainer(
  Color bgColor,
  String letter, {
  bool isGoogle = false,
  bool isMicrosoft = false,
}) {
  // Use SvgPicture.network for the Google SVG logo
  if (isGoogle) {
    return SvgPicture.network(
      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
      width: 40,
      height: 40,
      placeholderBuilder: (BuildContext context) =>
          const CircularProgressIndicator(), // Optional: show a loader
    );
  }
  // The Microsoft logo is a PNG, so Image.network is correct here
  if (isMicrosoft) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/512px-Microsoft_logo.svg.png',
      width: 40,
      height: 40,
    );
  }
  // Placeholder for others
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

Widget _buildStockItem({
  required Widget logo,
  required String ticker,
  required String company,
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
        // THIS IS THE FIX: Wrap the Column in an Expanded widget
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticker,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                company,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                overflow:
                    TextOverflow.ellipsis, // Prevents long text from wrapping
              ),
            ],
          ),
        ),
        // The Spacer is no longer needed when using Expanded here.
        // const Spacer(),
        SizedBox(
          width: 80,
          height: 40,
          child: _buildMiniChart(data, changeColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\$$price",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Icon(
                  change.startsWith('+')
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: changeColor,
                  size: 20,
                ),
                Text(
                  change.replaceAll(RegExp(r'[+-]'), ''),
                  style: TextStyle(color: changeColor, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMiniChart(List<double> data, Color color) {
  return LineChart(
    LineChartData(
      // The old way of hiding grid data still works, but you can be more explicit.
      gridData: const FlGridData(show: false),

      // THIS IS THE FIX: The `show` property is replaced by this new structure.
      // We are explicitly telling each axis not to show its titles.
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

Widget _buildToolsGrid() {
  return Row(
    children: [
      Expanded(
        child: _buildToolItem(Icons.campaign, "IPO", const Color(0xFFE3D9FF)),
      ),
      Expanded(
        child: _buildToolItem(Icons.newspaper, "NEWS", const Color(0xFFD9EFFF)),
      ),
      Expanded(
        child: _buildToolItem(
          Icons.broadcast_on_home,
          "COMMUNITY",
          const Color(0xFFD9EFFF),
        ),
      ),
      Expanded(
        child: _buildToolItem(Icons.star, "EVENT", const Color(0xFFFFDDC4)),
      ),
      Expanded(
        child: _buildToolItem(
          Icons.calculate,
          "CHARGES",
          const Color(0xFFD0F2E3),
        ),
      ),
    ],
  );
}

Widget _buildToolItem(IconData icon, String label, Color bgColor) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
      const SizedBox(height: 8),
      // ✨ FIX: Wrap the Text widget in a SizedBox with a fixed height.
      Text(
        label,
        style: TextStyle(color: Colors.grey[700], fontSize: 10),
        textAlign: TextAlign.center,
      ),
    ],
  );
}
