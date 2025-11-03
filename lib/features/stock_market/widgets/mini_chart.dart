import 'dart:math';

import 'package:bullxchange/models/instrument_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A small reusable mini chart widget used across the app.
///
/// Supports constructing from raw `data` or from an `Instrument` (it will
/// simulate/derive a small dataset from the instrument's liveData similar to
/// the previous inline implementations).
class MiniChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double strokeWidth;
  final bool enableTooltip;

  const MiniChart({
    super.key,
    required this.data,
    required this.color,
    this.strokeWidth = 2.0,
    this.enableTooltip = false,
  });

  /// Create a mini chart from an [Instrument]. This mirrors the previous
  /// inline implementations that generated 15 data points from instrument
  /// liveData (ltp, netChange) and a deterministic Random seeded by symbol.
  factory MiniChart.fromInstrument({
    required Instrument instrument,
    required Color color,
    double strokeWidth = 2.0,
    bool enableTooltip = false,
  }) {
    final ltp =
        num.tryParse(
          instrument.liveData['ltp']?.toString() ?? '',
        )?.toDouble() ??
        0.0;
    final netChange =
        num.tryParse(
          instrument.liveData['netChange']?.toString() ?? '',
        )?.toDouble() ??
        0.0;

    List<double> points;
    if (ltp == 0.0) {
      points = List<double>.generate(15, (_) => 1.0);
    } else {
      final startPrice = ltp - netChange;
      points = <double>[];
      final random = Random(instrument.symbol.hashCode);
      for (int i = 0; i < 15; i++) {
        if (i == 14) {
          points.add(ltp);
        } else {
          double progress = i / 14.0;
          double priceAtProgress = startPrice + (netChange * progress);
          double variance = ltp * 0.01 * (random.nextDouble() - 0.5);
          points.add(priceAtProgress + variance);
        }
      }
    }

    return MiniChart(
      data: points,
      color: color,
      strokeWidth: strokeWidth,
      enableTooltip: enableTooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    // compute min/max with small buffer
    final double minY = data.reduce((a, b) => a < b ? a : b);
    final double maxY = data.reduce((a, b) => a > b ? a : b);
    final double yRange = maxY - minY;
    final double chartMinY = (yRange.isFinite) ? minY - yRange * 0.1 : minY - 1;
    final double chartMaxY = (yRange.isFinite) ? maxY + yRange * 0.1 : maxY + 1;

    return LineChart(
      LineChartData(
        minY: chartMinY.isFinite ? chartMinY : null,
        maxY: chartMaxY.isFinite ? chartMaxY : null,
        clipData: FlClipData.none(),
        lineTouchData: enableTooltip
            ? LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.black87,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        '₹${barSpot.y.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              )
            : const LineTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: color,
            barWidth: strokeWidth,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withAlpha((0.2 * 255).round()),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
