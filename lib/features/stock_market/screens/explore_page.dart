import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/features/tools/coming_soon_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:provider/provider.dart';
import 'view_all_page.dart';
import 'package:bullxchange/features/tools/charges_calculator_tool.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.topGainers.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          );
        }
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  provider.errorMessage!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // --- Top Gainers Section ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _buildSectionHeader(context, "Top Gainers"),
              ),
              _buildStockList(provider.topGainers.take(4).toList(), context),

              const SizedBox(height: 24),

              // --- Top Losers Section ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: _buildSectionHeader(context, "Top Losers"),
              ),
              _buildStockList(provider.topLosers.take(4).toList(), context),

              const SizedBox(height: 32),

              // --- Tools Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSectionHeader(context, "Tools"),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  final stockCategories = [
    "Top Gainers",
    "Top Losers",
    "Most Active by Volume",
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 10,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      if (stockCategories.contains(title))
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewAllPage()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              // Adaptive Background:
              // Dark Mode: slightly lighter than background (surface-like)
              // Light Mode: very faint primary color or gray
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "View all",
                  style: TextStyle(
                    // Adaptive Text Color:
                    // Dark Mode: White/Light Grey for contrast
                    // Light Mode: Primary color (Branding)
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : colorScheme.primary,
                ),
              ],
            ),
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
  return Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: StockCard(
      instrument: instrument,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockDetailPage(instrument: instrument),
        ),
      ),
      fontSize: 10,
      showChart: true,
    ),
  );
}

Widget _buildToolsGrid(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  // Define base colors but adjust opacity for modern glass/flat look
  final Color primaryBase = colorScheme.primary;
  final Color secondaryBase = colorScheme.secondary;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildToolItem(
            context,
            Icons.campaign_rounded,
            "IPO",
            primaryBase,
          ),
        ),
        Expanded(
          child: _buildToolItem(
            context,
            Icons.newspaper_rounded,
            "NEWS",
            secondaryBase,
          ),
        ),
        Expanded(
          child: _buildToolItem(
            context,
            Icons.diversity_3_rounded,
            "COMMUNITY",
            primaryBase,
          ),
        ),
        Expanded(
          child: _buildToolItem(
            context,
            Icons.event_note_rounded,
            "EVENT",
            secondaryBase,
          ),
        ),
        Expanded(
          child: _buildToolItem(
            context,
            Icons.calculate_rounded,
            "CHARGES",
            primaryBase,
          ),
        ),
      ],
    ),
  );
}

Widget _buildToolItem(
  BuildContext context,
  IconData icon,
  String label,
  Color baseColor,
) {
  final theme = Theme.of(context);
  final bool isComingSoon = label != "CHARGES";

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      if (isComingSoon) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ComingSoonPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChargesApp()),
        );
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: baseColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}



