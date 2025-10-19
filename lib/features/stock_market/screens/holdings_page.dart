import 'dart:math';

import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

// --- Portfolio Data Structure ---
// This now holds the core information for your portfolio.
// In a real app, this would be fetched from a user's account.
final List<Map<String, dynamic>> userPortfolioData = [
  {'token': '2869', 'shares': 10, 'investedPrice': 3050.50}, // RADICO-EQ
  {'token': '1570', 'shares': 5, 'investedPrice': 1410.75}, // JINDALPHOT-EQ
  {'token': '11173', 'shares': 15, 'investedPrice': 565.20}, // TVSELECT-EQ
  {'token': '14977', 'shares': 20, 'investedPrice': 85.10}, // SUMIT-EQ
];

class HoldingsPage extends StatelessWidget {
  const HoldingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to get live data from the provider
    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // --- Data Processing ---
        final portfolioTokens = userPortfolioData
            .map((p) => p['token'])
            .toSet();
        final holdingsWithLiveData = provider.allNSEStocks
            .where((stock) => portfolioTokens.contains(stock.token))
            .toList();

        double currentValue = 0;
        double investedValue = 0;
        double dayReturns = 0;

        for (var stock in holdingsWithLiveData) {
          final portfolioInfo = userPortfolioData.firstWhere(
            (p) => p['token'] == stock.token,
          );
          final shares = portfolioInfo['shares'] as int;
          final investedPrice = portfolioInfo['investedPrice'] as double;
          final ltp = (stock.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
          final netChange =
              (stock.liveData['netChange'] as num?)?.toDouble() ?? 0.0;

          currentValue += ltp * shares;
          investedValue += investedPrice * shares;
          dayReturns += netChange * shares;
        }

        final totalReturns = currentValue - investedValue;

        // ✨ FIX: Use a Column to prevent nested scrolling errors.
        return Column(
          children: [
            // --- 1. Dynamic Summary Card ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSummaryCard(
                currentValue,
                totalReturns,
                investedValue,
                dayReturns,
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Dynamic Holdings List ---
            ...holdingsWithLiveData.map((instrument) {
              final portfolioInfo = userPortfolioData.firstWhere(
                (p) => p['token'] == instrument.token,
              );
              return _buildStockItem(
                instrument: instrument,
                shares: portfolioInfo['shares'] as int,
              );
            }),
          ],
        );
      },
    );
  }
}

// --- Reusable Widgets ---

Widget _buildSummaryCard(
  double currentValue,
  double totalReturns,
  double investedValue,
  double dayReturns,
) {
  final double totalReturnPercent = investedValue > 0
      ? (totalReturns / investedValue) * 100
      : 0;

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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryColumn("Current", currentValue),
            _buildSummaryColumn(
              "Total returns",
              totalReturns,
              percent: totalReturnPercent,
              isReturn: true,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryColumn("Invested", investedValue),
            _buildSummaryColumn("1D returns", dayReturns, isReturn: true),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSummaryColumn(
  String title,
  double value, {
  double? percent,
  bool isReturn = false,
}) {
  final sign = value > 0 ? "+" : "";
  final color = value > 0 ? Colors.greenAccent : Colors.redAccent;

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
            isReturn
                ? "$sign₹${value.toStringAsFixed(2)}"
                : "₹${value.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isReturn && percent != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$sign${percent.toStringAsFixed(2)}%",
                style: const TextStyle(
                  color: Colors.white,
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

Widget _buildStockItem({required Instrument instrument, required int shares}) {
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
                "$shares shares",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        // Chart and Price info are now driven by live data
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
              "₹${(ltp * shares).toStringAsFixed(2)}",
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
  if (name.toLowerCase().contains('google')) {
    return SvgPicture.network(
      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
      width: 40,
      height: 40,
    );
  }
  if (name.toLowerCase().contains('microsoft')) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/240px-Microsoft_logo.svg.png',
      width: 40,
      height: 40,
    );
  }

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
  if (ltp == 0.0) return Container(); // Return empty if no data

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
