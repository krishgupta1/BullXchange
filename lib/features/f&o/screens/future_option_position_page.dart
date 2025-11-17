import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- ⭐️ STATIC F&O POSITIONS PAGE ---
class FnoPositionsPage extends StatelessWidget {
  const FnoPositionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. Hardcoded data for the summary card ---
    const double totalPnl = 4320.75;
    const double totalInvestment = 88500.0; // Example: Total margin used

    // --- 2. Static list of F&O position items ---
    // Set to 'false' to see the empty state
    const bool hasPositions = true;

    // ignore: dead_code
    if (!hasPositions) {
      return const Center(child: _EmptyState());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 3. Re-used Summary Card ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildFnoSummaryCard(
              totalPnl,
              totalInvestment,
              onExitAll: () {
                // Static: No action
              },
            ),
          ),
          const SizedBox(height: 24),

          // --- 4. Section Title ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Open F&O Positions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // --- 5. Hardcoded List of F&O Items ---
          _FnoPositionItem(
            symbol: "NIFTY 28NOV25 24500 CE",
            lots: 2,
            lotSize: 50,
            avgPrice: 120.50,
            ltp: 142.75,
            logoLetter: "N",
            logoColor: Colors.blue.shade700,
          ),
          _FnoPositionItem(
            symbol: "BANKNIFTY 28NOV25 51000 PE",
            lots: 1,
            lotSize: 15,
            avgPrice: 310.20,
            ltp: 280.40,
            logoLetter: "B",
            logoColor: Colors.red.shade700,
          ),
          _FnoPositionItem(
            symbol: "FINNIFTY 25NOV25 22000 CE",
            lots: 3,
            lotSize: 40,
            avgPrice: 65.10,
            ltp: 68.30,
            logoLetter: "F",
            logoColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }
}

// --- ⭐️ STATIC F&O LIST ITEM ---
// (Styled to match your PositionStockItem)
class _FnoPositionItem extends StatelessWidget {
  final String symbol;
  final int lots;
  final int lotSize;
  final double avgPrice;
  final double ltp;
  final String logoLetter;
  final Color logoColor;

  const _FnoPositionItem({
    required this.symbol,
    required this.lots,
    required this.lotSize,
    required this.avgPrice,
    required this.ltp,
    required this.logoLetter,
    required this.logoColor,
  });

  // Helper widget copied from your code for visual consistency
  Widget _buildLogoContainer(String letter, Color color) {
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

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    // F&O Calculations
    final int totalQuantity = lots * lotSize;
    final double pnl = (ltp - avgPrice) * totalQuantity;
    final double pnlPercent = (avgPrice > 0)
        ? ((ltp - avgPrice) / avgPrice) * 100
        : 0.0;
    final double currentValue = ltp * totalQuantity;

    final String sign = pnl >= 0 ? "+" : "-";
    final Color color = pnl >= 0 ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () {
        // Static: No action, but could open a bottom sheet
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            _buildLogoContainer(logoLetter, logoColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "$lots Lots ($totalQuantity Qty)",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceFormatter.format(currentValue),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Use .abs() to avoid double signs (e.g., "-₹-50")
                  "$sign₹${pnl.abs().toStringAsFixed(2)} ($sign${pnlPercent.abs().toStringAsFixed(2)}%)",
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- ⭐️ SUMMARY CARD ---
// (Copied directly from your PositionPage code for identical style)
Widget _buildFnoSummaryCard(
  double totalPnl,
  double totalInvestment, {
  required VoidCallback onExitAll,
}) {
  final sign = totalPnl >= 0 ? "+" : "-";
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
          "Total Profit & Loss (F&O)",
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
                label: const Text("Exit all F&O"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onExitAll,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// --- ⭐️ EMPTY STATE WIDGET ---
// (Copied from your code and text modified for F&O)
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Icon(Icons.work_history_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "No Open F&O Positions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Your open F&O positions for the day will appear here.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
