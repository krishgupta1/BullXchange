import 'package:bullxchange/features/f&o/screens/option_chain_page.dart';
import 'package:bullxchange/features/f&o/widgets/fno_card.dart';
import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart'; // For navigation
// For chart
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
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
    return FnOCard(
      instrument: instrument,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OptionChainPage(symbol: 'NIFTY'),
        ),
      ),
      fontSize: 12,
    );
  }

  // Helper to create the colored letter logo

  // Helper to create the mini-chart data
}
