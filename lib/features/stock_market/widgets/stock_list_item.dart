import 'dart:math';
import 'package:bullxchange/features/stock_market/screens/stock_detail_page.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';

class StockListItem extends StatelessWidget {
  const StockListItem({super.key, required this.instrument});

  final Instrument instrument;

  @override
  Widget build(BuildContext context) {
    final ltp = instrument.liveData["ltp"]?.toString() ?? "--";
    final percentChange =
        num.tryParse(
          instrument.liveData["percentChange"].toString(),
        )?.toDouble() ??
        0.0;
    final changeColor = percentChange >= 0
        ? const Color(0xFF1EAB58)
        : Colors.red;
    final List<double> chartData = _createSimulatedChartData(instrument);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailPage(instrument: instrument),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            SmartLogo(instrument: instrument, radius: 0),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instrument.symbol.replaceAll('-EQ', ''),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    instrument.name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              height: 40,
              child: MiniChart(data: chartData, color: changeColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹$ltp",
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(
                      percentChange >= 0
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: changeColor,
                      size: 20,
                    ),
                    Text(
                      "${percentChange.abs().toStringAsFixed(2)}%",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: changeColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // This helper function is now part of this file
  List<double> _createSimulatedChartData(Instrument instrument) {
    final ltp =
        num.tryParse(instrument.liveData['ltp'].toString())?.toDouble() ?? 0.0;
    final netChange =
        num.tryParse(instrument.liveData['netChange'].toString())?.toDouble() ??
        0.0;
    if (ltp == 0.0) return List<double>.generate(15, (_) => 1.0);
    final startPrice = ltp - netChange;
    final points = <double>[];
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
    return points;
  }
}
