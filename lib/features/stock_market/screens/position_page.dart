// lib/pages/position_page.dart (or wherever you have it)
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <-- IMPORT FOR FORMATTING
import 'package:provider/provider.dart';
// import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart'; // MiniChart is commented out

class PositionPage extends StatelessWidget {
  const PositionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. CONSUME BOTH PROVIDERS ---
    return Consumer2<UserProfileDataModel?, InstrumentProvider>(
      builder: (context, userProfile, instrumentProvider, child) {
        // --- 2. GET LIVE POSITIONS FROM USER PROFILE ---
        if (userProfile == null || userProfile.positions.isEmpty) {
          return const _EmptyState();
        }

        final userPositions = userProfile.positions;

        // --- 3. CALCULATE P&L AND INVESTMENT FROM LIVE DATA ---
        double totalOverallPnl = 0;
        double totalInvestment = 0;
        List<Widget> positionWidgets = [];

        for (var position in userPositions) {
          // Find the matching instrument from the provider
          final instrument = instrumentProvider.getInstrumentBySymbol(
            position.stockSymbol,
          );

          if (instrument == null) continue; // Skip if no live data found

          // --- P&L CALCULATION (OVERALL P&L) ---
          final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
          final avgBuyPrice = position.transactionPrice;
          final quantity = position.quantity;

          final double pnl = (ltp - avgBuyPrice) * quantity;
          final double investment = avgBuyPrice * quantity;

          // --- THIS IS THE NEW VALUE YOU WANTED ---
          final double currentTotalValue = ltp * quantity;

          double pnlPercent = 0.0;
          if (investment > 0) {
            pnlPercent = (pnl / investment) * 100;
          }
          // --- END P&L CALCULATION ---

          totalOverallPnl += pnl;
          totalInvestment += investment;

          positionWidgets.add(
            _buildStockItem(
              instrument: instrument,
              shares: position.quantity,
              pnl: pnl,
              pnlPercent: pnlPercent,
              currentTotalValue: currentTotalValue, // <-- PASS NEW VALUE
            ),
          );
        }

        if (positionWidgets.isEmpty) {
          return const _EmptyState();
        }

        // --- 4. BUILD THE UI ---
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dynamic Position Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildPositionSummaryCard(
                  totalOverallPnl,
                  totalInvestment,
                ),
              ),
              const SizedBox(height: 24),

              // 2. "Intraday" Section Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Intraday Positions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              // 3. Dynamic Positions List
              ...positionWidgets,
            ],
          ),
        );
      },
    );
  }
}

// --- _EmptyState is UNCHANGED ---
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

// --- _buildPositionSummaryCard is UNCHANGED ---
Widget _buildPositionSummaryCard(double totalPnl, double totalInvestment) {
  final sign = totalPnl >= 0 ? "+" : "";
  final color = totalPnl >= 0 ? Colors.greenAccent : Colors.redAccent;

  double totalPnlPercent = 0.0;
  if (totalInvestment > 0) {
    totalPnlPercent = (totalPnl / totalInvestment) * 100;
  }

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
              "$sign₹${totalPnl.abs().toStringAsFixed(2)}",
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
                "$sign${totalPnlPercent.abs().toStringAsFixed(2)}%",
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
                onPressed: () {
                  // TODO: Implement "Exit All Positions" logic
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// --- THIS IS THE UPDATED WIDGET ---
Widget _buildStockItem({
  required Instrument instrument,
  required int shares,
  required double pnl,
  required double pnlPercent,
  required double currentTotalValue, // <-- UPDATED PARAMETER
}) {
  final changeColor = pnl >= 0 ? Colors.green : Colors.red;
  final sign = pnl >= 0 ? '+' : '';

  // --- ADDED FORMATTER ---
  final priceFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      children: [
        SmartLogo(instrument: instrument, radius: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instrument.symbol.replaceAll('-EQ', ''),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$shares Shares',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // --- UPDATED THIS TEXT WIDGET ---
            Text(
              priceFormatter.format(currentTotalValue), // e.g., "₹4,409.00"
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            // ---
            Text(
              "$sign₹${pnl.abs().toStringAsFixed(2)} ($sign${pnlPercent.abs().toStringAsFixed(2)}%)",
              style: TextStyle(color: changeColor, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}
