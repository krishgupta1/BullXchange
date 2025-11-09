import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/f&o/screens/option_chain_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';

// --- ⭐️ 1. 'SmartLogo' WIDGET IMPORT KIYA (LOGO KE LIYE) ---
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';

class FutureOptionExplorePage extends StatelessWidget {
  const FutureOptionExplorePage({super.key});

  // Helper to get the correct option chain symbol
  // (Yeh bug fix waise hi hai)
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
    return SingleChildScrollView(
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
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // --- ⭐️ 2. LAYOUT: 'GridView' WAPAS AA GAYA ---
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cards per row
                  childAspectRatio: 1.1, // Card ki height/width
                  crossAxisSpacing: 12, // Beech mein space
                  mainAxisSpacing: 12, // Beech mein space
                ),
                itemCount: validIndices.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final instrument = validIndices[index];
                  final optionSymbol = _getOptionChainSymbol(instrument);

                  // --- ⭐️ 3. CARD: WHITE CARD '_IndexGridCard' USE HO RAHA HAI ---
                  return _IndexGridCard(
                    instrument: instrument,
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
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  // Header (Waise hi hai)
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// --- ⭐️ 4. WHITE CARD WIDGET 'Modern Touch' KE SAATH ---
class _IndexGridCard extends StatelessWidget {
  final Instrument instrument;
  final VoidCallback onTap;

  const _IndexGridCard({required this.instrument, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    final change = (instrument.liveData['change'] as num?)?.toDouble() ?? 0.0;
    final changePercent =
        (instrument.liveData['change_percent'] as num?)?.toDouble() ?? 0.0;

    final color = change >= 0 ? Colors.green : Colors.red;
    final sign = change >= 0 ? '+' : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // --- Background: White (ya dark mode mein dark) ---
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          // --- Modern Touch: Halka border ---
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          // --- Modern Touch: Halka shadow ---
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Logo 'SmartLogo' se aa raha hai ---
                SmartLogo(instrument: instrument, radius: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instrument.name,
                    // --- Text Color: Default (black in light mode) ---
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              ltp.toStringAsFixed(2),
              // --- Text Color: Default (black in light mode) ---
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$sign${change.toStringAsFixed(2)} ($sign${changePercent.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: color, // Yeh green/red rahega
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
