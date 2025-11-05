// lib/pages/future_option_explore_page.dart

import 'dart:math'; // For chart
import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart'; // For navigation
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart'; // For chart
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // For logo
import 'package:provider/provider.dart';

class FutureOptionExplorePage extends StatelessWidget {
  const FutureOptionExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20), // Add some top padding
          // --- 1. Top Traded Section (Spot Indices) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSectionHeader(context, "Top Traded"),
          ),
          const SizedBox(height: 10),

          // This Consumer now builds a vertical list, just like Top Gainers
          Consumer<InstrumentProvider>(
            builder: (context, instProvider, child) {
              // Get all 6 spot indices
              final List<Instrument?> allIndices = [
                instProvider.nifty50,
                instProvider.bankNifty,
                instProvider.finNifty,
                instProvider.midcapNifty,
                instProvider.sensex,
                instProvider.bankex,
              ];

              // Filter out any empty/loading instruments
              final List<Instrument> validIndices = allIndices
                  .whereType<Instrument>()
                  .where((inst) => inst.token.isNotEmpty)
                  .toList();

              if (instProvider.isLoading && validIndices.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Use the _buildStockList helper (copied from ExplorePage)
              return _buildStockList(validIndices, context);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---
  // --- ALL HELPERS BELOW ARE COPIED/ADAPTED FROM EXPLOREPAGE.DART ---
  // ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // No "View all" button needed here
      ],
    );
  }

  // This is the helper that creates the vertical list
  Widget _buildStockList(List<Instrument> topStocks, BuildContext context) {
    return Column(
      children: topStocks
          .map((instrument) => _buildStockItem(instrument, context))
          .toList(),
    );
  }

  // This is the helper that creates the row (Logo, Name, Chart, Price)
  Widget _buildStockItem(Instrument instrument, BuildContext context) {
    final ltp = instrument.liveData["ltp"]?.toString() ?? "--";
    final percentChange =
        num.tryParse(
          instrument.liveData["percentChange"].toString(),
        )?.toDouble() ??
        0.0;
    final changeColor = percentChange >= 0
        ? const Color(0xFF1EAB58)
        : Colors.red;
    final List<double> chartData = _createSimulatedChartData(instrument);

    return Material(
      color: Colors.transparent, // Required for InkWell ripple effect
      child: InkWell(
        onTap: () {
          // This navigation will now work for indices too
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailPage(instrument: instrument),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              _buildLogoContainer(instrument.name), // Use name for logo
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instrument.symbol.replaceAll('-EQ', ''), // Use symbol
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      instrument.name, // Use name
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
      ),
    );
  }

  // Helper to create the colored letter logo
  Widget _buildLogoContainer(String name) {
    if (name.toLowerCase().contains('google')) {
      return SvgPicture.network(
        'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
        width: 40,
        height: 40,
      );
    }
    // ... (add other specific logos if you want) ...

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

  // Helper to create the mini-chart data
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
}
