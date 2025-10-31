import 'dart:math';
import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'view_all_page.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // The 'context' is available here
    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.topGainers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return SingleChildScrollView(
          // Wrapped in SingleChildScrollView to prevent overflow
          child: Column(
            children: [
              // --- Top Gainers Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSectionHeader(context, "Top Gainers"),
              ),
              const SizedBox(height: 10),
              // We pass 'context' down to the next function
              _buildStockList(provider.topGainers.take(4).toList(), context),
              const SizedBox(height: 24),

              // --- Top Losers Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSectionHeader(context, "Top Losers"),
              ),
              const SizedBox(height: 10),
              _buildStockList(provider.topLosers.take(4).toList(), context),
              const SizedBox(height: 24),

              // --- Tools Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSectionHeader(context, "Tools"),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildToolsGrid(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// Helper widgets below are fully corrected and self-contained.

Widget _buildSectionHeader(BuildContext context, String title) {
  final stockCategories = [
    "Top Gainers",
    "Top Losers",
    "Most Active by Volume",
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      if (stockCategories.contains(title))
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewAllPage()),
          ),
          child: const Text(
            "View all",
            style: TextStyle(color: Color(0xFFDB1B57), fontSize: 13),
          ),
        ),
    ],
  );
}

// ✨ FIX: This function now accepts 'BuildContext'
Widget _buildStockList(List<Instrument> topStocks, BuildContext context) {
  return Column(
    children: topStocks
        .map(
          (instrument) => _buildStockItem(instrument, context),
        ) // And passes it here
        .toList(),
  );
}

// ✨ FIX: This widget now accepts 'BuildContext' so Navigator can use it
Widget _buildStockItem(Instrument instrument, BuildContext context) {
  final ltp = instrument.liveData["ltp"]?.toString() ?? "--";
  final percentChange =
      num.tryParse(
        instrument.liveData["percentChange"].toString(),
      )?.toDouble() ??
      0.0;
  final changeColor = percentChange >= 0 ? const Color(0xFF1EAB58) : Colors.red;
  final List<double> chartData = _createSimulatedChartData(instrument);

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context, // Now 'context' is available to use
        MaterialPageRoute(
          builder: (context) => StockDetailPage(instrument: instrument),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          _buildLogoContainer(instrument.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrument.symbol.replaceAll('-EQ', ''),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
            width: 80,
            height: 40,
            child: MiniChart(data: chartData, color: changeColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹$ltp",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  Icon(
                    percentChange >= 0
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: changeColor,
                    size: 20,
                  ),
                  Text(
                    "${percentChange.abs().toStringAsFixed(2)}%",
                    style: TextStyle(color: changeColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// (No changes needed in the widgets below this line)

List<double> _createSimulatedChartData(Instrument instrument) {
  final ltp =
      num.tryParse(instrument.liveData['ltp'].toString())?.toDouble() ?? 0.0;
  final netChange =
      num.tryParse(instrument.liveData['netChange'].toString())?.toDouble() ??
      0.0;

  if (ltp == 0.0) return List<double>.generate(15, (_) => 1.0);
  final startPrice = ltp - netChange;
  final points = <double>[];
  final random = Random(instrument.symbol.hashCode);

  for (int i = 0; i < 15; i++) {
    if (i == 14) {
      points.add(ltp);
    } else {
      double progress = i / 14.0;
      double priceAtProgress = startPrice + (netChange * progress);
      double variance = ltp * 0.01 * (random.nextDouble() - 0.5);
      points.add(priceAtProgress + variance);
    }
  }
  return points;
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
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/512px-Microsoft_logo.svg.png',
      width: 40,
      height: 40,
    );
  }
  if (name.toLowerCase().contains('nike')) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png',
      width: 40,
      height: 40,
      color: Colors.black,
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

// Replaced by reusable MiniChart widget in lib/widgets/mini_chart.dart

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
      Text(
        label,
        style: TextStyle(color: Colors.grey[700], fontSize: 10),
        textAlign: TextAlign.center,
      ),
    ],
  );
}
