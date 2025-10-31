import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
// restored: removed company_name helper import
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';

// --- Mock Data for Open Orders ---
// In a real app, this would be fetched from the broker's order book.
final List<Map<String, dynamic>> userOpenOrders = [
  {'token': '2869', 'orderPrice': 3080.00, 'quantity': 10, 'type': 'BUY'},
  {'token': '1570', 'orderPrice': 1450.00, 'quantity': 20, 'type': 'SELL'},
  {'token': '11173', 'orderPrice': 555.50, 'quantity': 50, 'type': 'BUY'},
];

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // --- Data Processing ---
        final orderTokens = userOpenOrders.map((p) => p['token']).toSet();
        final ordersWithLiveData = provider.allNSEStocks
            .where((stock) => orderTokens.contains(stock.token))
            .toList();

        // Handle case where there are no open orders
        if (ordersWithLiveData.isEmpty) {
          return const _EmptyState();
        }

        // ✨ FIX: Use a Column to prevent nested scrolling errors.
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- Header with collapsible icon ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Open orders (${ordersWithLiveData.length})",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_up),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // --- Cancel all / Qty Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        label: Text(
                          "Cancel all",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        onPressed: () {},
                      ),
                      Text(
                        "Qty/Price",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- Orders List ---
            ...ordersWithLiveData.map((instrument) {
              final orderInfo = userOpenOrders.firstWhere(
                (p) => p['token'] == instrument.token,
              );
              return _buildOrderItem(
                instrument: instrument,
                orderInfo: orderInfo,
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
        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "No Pending Orders",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Your open orders for the day will appear here.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget _buildOrderItem({
  required Instrument instrument,
  required Map<String, dynamic> orderInfo,
}) {
  final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final changeColor = netChange >= 0 ? Colors.green : Colors.red;
  final orderType = orderInfo['type'] as String;
  final orderPrice = orderInfo['orderPrice'] as double;
  final quantity = orderInfo['quantity'] as int;

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
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "$orderType ",
                      style: TextStyle(
                        color: orderType == 'BUY' ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                instrument.symbol.replaceAll(
                  '-EQ',
                  '',
                ), // restored: show symbol bold
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "Mkt ₹${ltp.toStringAsFixed(2)}",
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
              "Intraday",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              "$quantity",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              "At ₹${orderPrice.toStringAsFixed(2)}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
