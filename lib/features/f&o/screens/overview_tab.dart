import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/market_range_slider.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  String _formatNum(double? val) {
    if (val == null || val == 0) return "-";
    return NumberFormat("#,##0.00", "en_US").format(val);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OptionChainProvider>();
    final data = provider.overviewData;

    // Loading State
    if (provider.isOverviewLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty State
    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No Overview Data",
              style: TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: () => provider.fetchOptionChain(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final isNegative = data.priceChange < 0;
    final color = isNegative ? Colors.redAccent : Colors.greenAccent;

    return RefreshIndicator(
      onRefresh: () async => await provider.fetchOptionChain(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            Text(
              provider.symbol,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatNum(data.currentPrice),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${isNegative ? '' : '+'}${_formatNum(data.priceChange)} (${data.percentChange.toStringAsFixed(2)}%)",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. Performance Section
            Row(
              children: [
                const Text(
                  "Performance",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(height: 20),

            // Today's Range
            _RangeLabels(
              labelLow: "Today's Low",
              labelHigh: "Today's High",
              valLow: data.dayLow,
              valHigh: data.dayHigh,
            ),
            const SizedBox(height: 8),
            MarketRangeSlider(
              low: data.dayLow,
              high: data.dayHigh,
              current: data.currentPrice,
            ),

            const SizedBox(height: 24),

            // 52 Week Range
            _RangeLabels(
              labelLow: "52 Week Low",
              labelHigh: "52 Week High",
              valLow: data.yearLow,
              valHigh: data.yearHigh,
            ),
            const SizedBox(height: 8),
            MarketRangeSlider(
              low: data.yearLow,
              high: data.yearHigh,
              current: data.currentPrice,
            ),

            const SizedBox(height: 24),
            const Divider(color: Colors.grey, thickness: 0.2),
            const SizedBox(height: 16),

            // Open & Prev Close
            Row(
              children: [
                Expanded(
                  child: _StatItem(label: "Open", value: _formatNum(data.open)),
                ),
                Expanded(
                  child: _StatItem(
                    label: "Prev. Close",
                    value: _formatNum(data.prevClose),
                    alignEnd: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 0.2),

            // Lists
            _ListRow(title: "${provider.symbol} Companies"),
            _ListRow(title: "${provider.symbol} ETFs"),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets for OverviewTab ---

class _RangeLabels extends StatelessWidget {
  final String labelLow, labelHigh;
  final double valLow, valHigh;
  const _RangeLabels({
    required this.labelLow,
    required this.labelHigh,
    required this.valLow,
    required this.valHigh,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat("#,##0.00", "en_US");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labelLow,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              valLow == 0 ? "-" : f.format(valLow),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              labelHigh,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              valHigh == 0 ? "-" : f.format(valHigh),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final bool alignEnd;
  const _StatItem({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  final String title;
  const _ListRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
        Divider(color: Colors.grey.withOpacity(0.2), height: 1),
      ],
    );
  }
}
