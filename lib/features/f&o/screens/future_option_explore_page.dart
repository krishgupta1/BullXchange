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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
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

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    // REVERTED: Back to 1.0 (Square) as per your preference.
                    // This gives plenty of "free space inside" for the data.
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: validIndices.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final instrument = validIndices[index];
                    final optionSymbol = _getOptionChainSymbol(instrument);

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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🎨 RESTORED SQUARE CARD: Uses vertical space effectively
// ---------------------------------------------------------------------------
class _IndexGridCard extends StatelessWidget {
  final Instrument instrument;
  final VoidCallback onTap;

  const _IndexGridCard({required this.instrument, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final live = instrument.liveData;

    // Logic to fix +0.00 issue
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
    final color = isPositive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);
    final sign = isPositive ? '+' : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Section: Logo & Name
            Row(
              children: [
                SmartLogo(instrument: instrument, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatName(instrument.name),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        instrument.symbol.split('-').first,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. Spacer pushes price to bottom, utilizing the "free space inside"
            const Spacer(),

            // 3. Bottom Section: Price & Change
            Text(
              ltp.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$sign${change.toStringAsFixed(2)} ($sign${changePercent.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatName(String name) {
    return name.toUpperCase();
  }
}
