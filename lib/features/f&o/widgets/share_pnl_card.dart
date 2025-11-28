import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SharePnlCard extends StatelessWidget {
  final String symbol;
  final double pnl;
  final double roi;
  final double entryPrice;
  final double lastPrice;
  final bool isIntraday;

  const SharePnlCard({
    super.key,
    required this.symbol,
    required this.pnl,
    required this.roi,
    required this.entryPrice,
    required this.lastPrice,
    required this.isIntraday,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Theme
    final bool isProfit = pnl >= 0;
    final bool isSuperProfit = roi > 50.0; // Rocket mode if > 50% return

    List<Color> gradientColors;
    String imageAsset = "";
    IconData statusIcon;

    if (isSuperProfit) {
      // 🚀 Rocket Mode (Blue/Dark Theme)
      gradientColors = [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)];
      statusIcon = Icons.rocket_launch_rounded;
    } else if (isProfit) {
      // 🟢 Green Theme
      gradientColors = [const Color(0xFF11998e), const Color(0xFF38ef7d)];
      statusIcon = Icons.trending_up_rounded;
    } else {
      // 🔴 Red Theme
      gradientColors = [const Color(0xFFCB2D3E), const Color(0xFFEF473A)];
      statusIcon = Icons.trending_down_rounded;
    }

    final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("BullXchange", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  child: Text(isIntraday ? "INTRADAY" : "OPTIONS", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Symbol
            Text(symbol, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),

            // The Rocket Icon or Trend Icon
            Icon(statusIcon, size: 60, color: Colors.white.withOpacity(0.9)),
            const SizedBox(height: 20),

            // P&L Percentage (The big number)
            Text(
              "${pnl >= 0 ? '+' : ''}${roi.toStringAsFixed(2)}%",
              style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            Text("Return on Investment", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            
            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            // Grid Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailCol("Entry Price", f.format(entryPrice)),
                _detailCol("Last Price", f.format(lastPrice)),
                _detailCol("Profit/Loss", "${pnl >= 0 ? '+' : ''}${f.format(pnl)}", isBold: true),
              ],
            ),
            const SizedBox(height: 20),
            
            // Share Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context), // Placeholder for sharing logic
                icon: const Icon(Icons.share),
                label: const Text("Share P&L"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailCol(String label, String val, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}