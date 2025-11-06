import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_widgets/stock_card.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:provider/provider.dart';
import 'view_all_page.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // --- Top Gainers Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSectionHeader(context, "Top Gainers"),
              ),
              const SizedBox(height: 10),
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

Widget _buildStockList(List<Instrument> topStocks, BuildContext context) {
  return Column(
    children: topStocks
        .map((instrument) => _buildStockItem(instrument, context))
        .toList(),
  );
}

// ✨ FIXED: Using InkWell and Material to ensure the entire row is clickable
Widget _buildStockItem(Instrument instrument, BuildContext context) {
  return StockCard(
    instrument: instrument,
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailPage(instrument: instrument),
      ),
    ),
    fontSize: 12,
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
      Text(
        label,
        style: TextStyle(color: Colors.grey[700], fontSize: 10),
        textAlign: TextAlign.center,
      ),
    ],
  );
}
