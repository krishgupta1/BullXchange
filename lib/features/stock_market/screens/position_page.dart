import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';

// --- Mock Data for Intraday Positions ---
// In a real app, this would be fetched from the user's broker account.
final List<Map<String, dynamic>> userPositionsData = [
  {'token': '2742', 'shares': 50, 'avgBuyPrice': 270.50}, // SETFNIF50-EQ
  {'token': '1604', 'shares': 100, 'avgBuyPrice': 1350.00}, // JINDALPHOT-EQ
  {'token': '11536', 'shares': 30, 'avgBuyPrice': 5600.00}, // PILANIINVS-EQ
];

class PositionPage extends StatelessWidget {
  const PositionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // --- Data Processing ---
        final positionTokens = userPositionsData.map((p) => p['token']).toSet();
        final positionsWithLiveData = provider.allNSEStocks
            .where((stock) => positionTokens.contains(stock.token))
            .toList();

        // Handle case where there are no open positions
        if (positionsWithLiveData.isEmpty) {
          return const _EmptyState();
        }

        double totalPnl = 0;
        for (var stock in positionsWithLiveData) {
          final positionInfo = userPositionsData.firstWhere(
            (p) => p['token'] == stock.token,
          );
          final shares = positionInfo['shares'] as int;
          final netChange =
              (stock.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
          totalPnl += netChange * shares;
        }

        // ✨ FIX: Use a Column to prevent nested scrolling errors.
        return Column(
          children: [
            // --- 1. Dynamic Position Summary Card ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildPositionSummaryCard(totalPnl),
            ),
            const SizedBox(height: 24),

            // --- 2. "Intraday" Section Header ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Intraday Positions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // --- 3. Dynamic Positions List ---
            ...positionsWithLiveData.map((instrument) {
              final positionInfo = userPositionsData.firstWhere(
                (p) => p['token'] == instrument.token,
              );
              return _buildStockItem(
                instrument: instrument,
                shares: positionInfo['shares'] as int,
              );
            }),
          ],
        );
      },
    );
  }
}

// --- Reusable Widgets ---

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 20),
        Icon(Icons.work_history_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "No Open Positions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Your intraday trades for the day will appear here.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget _buildPositionSummaryCard(double totalPnl) {
  final sign = totalPnl >= 0 ? "+" : "";
  final color = totalPnl >= 0 ? Colors.greenAccent : Colors.redAccent;

  return Container(
    height: 170,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF6F4CFF), Color(0xFFDB1B57)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total Profit & Loss",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              "$sign₹${totalPnl.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Today",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Exit all"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStockItem({required Instrument instrument, required int shares}) {
  final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final pnl = netChange * shares;
  final changeColor = pnl >= 0 ? Colors.green : Colors.red;

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
                instrument.symbol, // restored: show symbol in bold
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                instrument.name, // restored: faded short name below symbol
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 30,
          child: MiniChart.fromInstrument(
            instrument: instrument,
            color: changeColor,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₹${ltp.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "P&L: ${pnl.toStringAsFixed(2)}",
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

// Replaced by reusable MiniChart widget in lib/widgets/mini_chart.dart
