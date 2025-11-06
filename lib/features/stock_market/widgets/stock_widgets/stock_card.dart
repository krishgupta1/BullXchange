import 'package:flutter/material.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';

class StockCard extends StatelessWidget {
  final Instrument instrument;
  final VoidCallback? onTap;
  final bool showChart;
  final bool showLogo;
  final double fontSize;

  const StockCard({
    super.key,
    required this.instrument,
    this.onTap,
    this.showChart = true,
    this.showLogo = true,
    this.fontSize = 12,
  });

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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            if (showLogo) ...[
              SmartLogo(instrument: instrument, radius: 0),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instrument.symbol.replaceAll('-EQ', ''),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                  Text(
                    instrument.name,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: fontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showChart) ...[
              SizedBox(
                width: 80,
                height: 40,
                child: MiniChart(
                  data: List.generate(20, (index) => index * percentChange),
                  color: changeColor,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ltp,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                Text(
                  "${percentChange >= 0 ? "+" : ""}$percentChange%",
                  style: TextStyle(color: changeColor, fontSize: fontSize),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
