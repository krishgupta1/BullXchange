import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:provider/provider.dart';
import 'view_all_page.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Get theme colors ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.topGainers.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              // --- ⭐️ MODIFIED: Use theme color ---
              color: colorScheme.secondary, // Pink
            ),
          );
        }
        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage!,
              // --- ⭐️ MODIFIED: Use theme error color ---
              style: TextStyle(color: colorScheme.error),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // --- Top Gainers Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // --- ⭐️ MODIFIED: Pass context for theme ---
                child: _buildSectionHeader(context, "Top Gainers"),
              ),
              const SizedBox(height: 10),
              _buildStockList(provider.topGainers.take(4).toList(), context),
              const SizedBox(height: 24),

              // --- Top Losers Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // --- ⭐️ MODIFIED: Pass context for theme ---
                child: _buildSectionHeader(context, "Top Losers"),
              ),
              const SizedBox(height: 10),
              _buildStockList(provider.topLosers.take(4).toList(), context),
              const SizedBox(height: 24),

              // --- Tools Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // --- ⭐️ MODIFIED: Pass context for theme ---
                child: _buildSectionHeader(context, "Tools"),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // --- ⭐️ MODIFIED: Pass context for theme ---
                child: _buildToolsGrid(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// --- Helper widgets ---

Widget _buildSectionHeader(BuildContext context, String title) {
  // --- ⭐️ Get theme colors ---
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

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
        // --- ⭐️ MODIFIED: Use theme text color ---
        // (colorScheme.onBackground)
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      if (stockCategories.contains(title))
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewAllPage()),
          ),
          child: Text(
            "View all",
            // --- ⭐️ MODIFIED: Use theme secondary color (Pink) ---
            style: TextStyle(color: colorScheme.secondary, fontSize: 13),
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

Widget _buildStockItem(Instrument instrument, BuildContext context) {
  // --- ❗️ IMPORTANT ---
  // Make sure your 'StockCard' widget is ALSO theme-aware
  // (i.e., it doesn't use hardcoded Colors.white or Colors.black).
  // It should use theme.colorScheme.surface for background
  // and theme.colorScheme.onSurface for text.
  // ---
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

Widget _buildToolsGrid(BuildContext context) {
  // --- ⭐️ Get theme colors ---
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  // --- ⭐️ Define theme-aware colors for backgrounds and icons ---
  // Yeh colors light/dark mode ke hisaab se automatically adjust honge
  final Color primaryContainer = colorScheme.primary.withOpacity(0.1);
  final Color primaryIcon = colorScheme.primary;

  final Color secondaryContainer = colorScheme.secondary.withOpacity(0.1);
  final Color secondaryIcon = colorScheme.secondary;

  return Row(
    children: [
      Expanded(
        child: _buildToolItem(
          context,
          Icons.campaign,
          "IPO",
          primaryContainer, // Theme BG
          primaryIcon, // Theme Icon
        ),
      ),
      Expanded(
        child: _buildToolItem(
          context,
          Icons.newspaper,
          "NEWS",
          secondaryContainer, // Theme BG
          secondaryIcon, // Theme Icon
        ),
      ),
      Expanded(
        child: _buildToolItem(
          context,
          Icons.broadcast_on_home,
          "COMMUNITY",
          primaryContainer, // Theme BG
          primaryIcon, // Theme Icon
        ),
      ),
      Expanded(
        child: _buildToolItem(
          context,
          Icons.star,
          "EVENT",
          secondaryContainer, // Theme BG
          secondaryIcon, // Theme Icon
        ),
      ),
      Expanded(
        child: _buildToolItem(
          context,
          Icons.calculate,
          "CHARGES",
          primaryContainer, // Theme BG
          primaryIcon, // Theme Icon
        ),
      ),
    ],
  );
}

Widget _buildToolItem(
  BuildContext context,
  IconData icon,
  String label,
  Color bgColor, // Theme color (from _buildToolsGrid)
  Color iconColor, // Theme color (from _buildToolsGrid)
) {
  // --- ⭐️ Get theme text color ---
  final theme = Theme.of(context);

  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor, // --- ⭐️ MODIFIED ---
          borderRadius: BorderRadius.circular(12),
        ),
        // --- ⭐️ MODIFIED ---
        child: Icon(icon, color: iconColor, size: 24),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        // --- ⭐️ MODIFIED: Use theme grey text color ---
        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    ],
  );
}
