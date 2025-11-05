import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';

class IndexCard extends StatelessWidget {
  final Instrument? instrument;
  final String? title; // Optional title override

  const IndexCard({super.key, required this.instrument, this.title});

  @override
  Widget build(BuildContext context) {
    // Logic pulled directly from your StockPage _buildIndexCard
    final name =
        title ?? // Use the override title if provided
        instrument?.name.toUpperCase().replaceFirst("NIFTY ", "") ??
        "LOADING...";
    final value = instrument?.liveData["ltp"]?.toStringAsFixed(2) ?? "0.00";
    final netChange =
        instrument?.liveData["netChange"]?.toStringAsFixed(2) ?? "0.00";
    final percentChange =
        instrument?.liveData["percentChange"]?.toStringAsFixed(2) ?? "0.00";

    final double changeValue = num.tryParse(netChange)?.toDouble() ?? 0.0;
    // Use isNegative check from FutureOptionPage for consistency
    final changeColor = changeValue.isNegative ? Colors.red : Colors.green;

    final changeText = "$netChange($percentChange%)";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value != "0.00" ? "₹$value" : "...",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              color: changeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
