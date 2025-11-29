import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/f&o/screens/option_chain_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';

class FutureOptionExplorePage extends StatelessWidget {
  const FutureOptionExplorePage({super.key});

  String _getOptionChainSymbol(Instrument instrument) {
    final name = instrument.name.toUpperCase();
    if (name.contains('NIFTY 50')) return 'NIFTY';
    if (name.contains('NIFTY BANK')) return 'BANKNIFTY';
    if (name.contains('FIN SERVICE')) return 'FINNIFTY';
    if (name.contains('MIDCAP')) return 'MIDCPNIFTY';
    if (name.contains('SENSEX')) return 'SENSEX';
    if (name.contains('BANKEX')) return 'BANKEX';
    return instrument.symbol.replaceAll('-INDEX', '');
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are in Dark Mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Transparent to use parent background
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Indices"),
            Consumer<InstrumentProvider>(
              builder: (context, instProvider, child) {
                final List<Instrument?> allIndices = [
                  instProvider.nifty50,
                  instProvider.bankNifty,
                  instProvider.finNifty,
                  instProvider.midcapNifty,
                  instProvider.sensex,
                  instProvider.bankex,
                ];

                final List<Instrument> validIndices = allIndices
                    .whereType<Instrument>()
                    .where((inst) => inst.token.isNotEmpty)
                    .toList();

                if (instProvider.isLoading && validIndices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return GridView.builder(
                  // ✨ FIX: Removed horizontal padding to align with parent
                  padding: const EdgeInsets.only(bottom: 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing:
                        16, // ✨ FIX: Increased to 16 to match top gap
                    mainAxisSpacing: 16, // ✨ FIX: Increased for consistency
                  ),
                  itemCount: validIndices.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final instrument = validIndices[index];
                    final optionSymbol = _getOptionChainSymbol(instrument);

                    return _IndexGridCard(
                      instrument: instrument,
                      isDarkMode: isDarkMode,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OptionChainPage(symbol: optionSymbol),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      // Adjusted padding to align text with the cards
      padding: const EdgeInsets.only(top: 10.0, bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🎨 ALIGNED CARD WIDGET
// ---------------------------------------------------------------------------
class _IndexGridCard extends StatelessWidget {
  final Instrument instrument;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _IndexGridCard({
    required this.instrument,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final live = instrument.liveData;
    final double ltp = double.tryParse(live['ltp']?.toString() ?? "0") ?? 0.0;
    final double prevClose =
        double.tryParse(
          live['close']?.toString() ?? live['prev_close']?.toString() ?? "0",
        ) ??
        0.0;

    double change = double.tryParse(live['change']?.toString() ?? "0") ?? 0.0;
    double changePercent =
        double.tryParse(live['change_percent']?.toString() ?? "0") ?? 0.0;

    if (change == 0.0 && prevClose != 0.0) {
      change = ltp - prevClose;
      changePercent = ((ltp - prevClose) / prevClose) * 100;
    }

    final isPositive = change >= 0;

    // UI Colors
    final displayColor = isPositive
        ? const Color(0xFF2E7D32) // Green
        : const Color(0xFFC62828); // Red

    final sign = isPositive ? '+' : '';

    // ✨ FIX: Color Matching
    // Matches the top cards (0xFF1C1C1E is standard dark surface)
    final cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  children: [
                    SmartLogo(instrument: instrument, radius: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instrument.name.toUpperCase(),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            instrument.symbol.split('-').first,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40,),

                // 2. Price Section
                Text(
                  ltp.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),

                // 3. Change Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$sign${change.toStringAsFixed(2)} ($sign${changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: displayColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
