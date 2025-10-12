import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:bullxchange/features/auth/widgets/app_back_button.dart';

class ViewAllPage extends StatelessWidget {
  const ViewAllPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        title: const Text(
          "Select Stocks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ADDED THE NEW SEARCH BAR HERE
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildAllStocksList(),
        ],
      ),
    );
  }
}

/// Builds the custom search bar UI as seen in the image.
Widget _buildSearchBar() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white, // Use named color for clarity
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: const Color(
          0xFF908FEC,
        ), // The light purple border color (8-digit hex)
        width: 2,
      ),
    ),
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(
            Icons.circle,
            color: Color(0xFFDB1B57), // A vibrant pink color
            size: 16,
          ),
        ),
        Expanded(
          child: Text(
            "Search company, stocks...",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(Icons.mic, color: Colors.grey),
        ),
      ],
    ),
  );
}

/// Builds the entire list of stock items.
Widget _buildAllStocksList() {
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
        ticker: 'GOOGL',
        company: 'Alphabet Inc.',
        price: '2.84k',
        change: '+0.58%',
        changeColor: const Color(0xFF1EAB58), // A nice green
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
        logo: _buildLogoContainer(Colors.black, 'N', isNike: true), // Nike
        ticker: 'NIKE',
        company: 'Nike, Inc.',
        price: '169.8',
        change: '-0.082%',
        changeColor: Colors.red,
        data: const [4, 3, 2, 4, 3, 2, 1],
      ),
      _buildStockItem(
        logo: _buildLogoContainer(
          const Color(0xFF1DB954),
          'S',
        ), // Spotify green
        ticker: 'SPOT',
        company: 'Spotify',
        price: '226.9',
        change: '+0.90%',
        changeColor: const Color(0xFF1EAB58),
        data: const [4, 5, 6, 5, 7, 8, 9],
      ),
      _buildStockItem(
        logo: _buildLogoContainer(const Color(0xFFD22F27), 'T'), // Tesla red
        ticker: 'TSLA',
        company: 'Tesla Motors',
        price: '701.16',
        change: '-1.41%',
        changeColor: Colors.red,
        data: const [9, 8, 6, 7, 5, 4, 2],
      ),
      _buildStockItem(
        logo: _buildLogoContainer(
          const Color(0xFF3B5998),
          'F',
        ), // Facebook blue
        ticker: 'FB',
        company: 'Facebook, Inc',
        price: '365.51',
        change: '+0.59%',
        changeColor: const Color(0xFF1EAB58),
        data: const [2, 3, 4, 6, 5, 7, 8],
      ),
    ],
  );
}

/// A flexible widget to create the company logo, handling
/// both simple colored circles and special network images.
Widget _buildLogoContainer(
  Color bgColor,
  String letter, {
  bool isGoogle = false,
  bool isMicrosoft = false,
  bool isNike = false,
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
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/512px-Microsoft_logo.svg.png',
      width: 40,
      height: 40,
    );
  }
  if (isNike) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png',
      width: 40,
      height: 40,
      color: Colors.black, // Apply the color filter to the SVG
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

/// Builds a single row for a stock item, including the logo,
/// company info, chart, and price.
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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

/// Creates a small line chart for a stock's performance.
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
