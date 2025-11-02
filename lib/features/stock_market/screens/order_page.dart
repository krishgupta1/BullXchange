// lib/features/stock_market/screens/order_page.dart
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Consume both the list of open orders (from the stream)
    //    and the InstrumentProvider (for live data).
    return Consumer2<List<OrderModel>, InstrumentProvider>(
      builder: (context, openOrders, provider, child) {
        // Handle case where there are no open orders
        if (openOrders.isEmpty) {
          return const _EmptyState();
        }

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
                        "Open orders (${openOrders.length})",
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
                        onPressed: () {
                          // TODO: Implement Cancel All Orders logic
                        },
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
            // 2. Build the list from the live order stream
            ...openOrders.map((order) {
              // 3. Find the matching instrument from the provider
              final instrument = provider.getInstrumentByToken(
                order.instrumentToken,
              );

              return _buildOrderItem(
                instrument: instrument, // This is an Instrument? (nullable)
                order: order,
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
  required Instrument? instrument, // <-- Accept nullable Instrument
  required OrderModel order,
}) {
  // Get LTP from instrument if it exists, otherwise use '...'
  final ltp = (instrument?.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument?.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final changeColor = netChange >= 0 ? Colors.green : Colors.red;

  // Get order info directly from the OrderModel
  final orderType = order.transactionType;
  final orderPrice = order.limitPrice;
  final quantity = order.quantity;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      children: [
        // --- THIS IS THE FIX ---
        // Conditionally build the SmartLogo if instrument is available,
        // otherwise build the placeholder using the order's company name.
        instrument != null
            ? SmartLogo(instrument: instrument, radius: 20)
            : _buildLogoContainer(order.companyName, radius: 20),
        // --- END OF FIX ---
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
                order.symbol, // Use symbol from order
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "Mkt ₹${ltp == 0.0 ? '--' : ltp.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 30,
          // Conditionally build the MiniChart
          child: instrument != null
              ? MiniChart.fromInstrument(
                  instrument: instrument,
                  color: changeColor,
                )
              : Container(
                  color: Colors.grey[200],
                ), // Placeholder if no instrument
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.productType, // 'INTRADAY' or 'DELIVERY'
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

/// Builds a placeholder logo based on the company name
/// (This logic is consistent with your holdings_page.dart)
Widget _buildLogoContainer(String name, {double radius = 20}) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
  // This logic uses the name's hashcode, creating varied colors
  final color = Colors.primaries[name.hashCode % Colors.primaries.length];
  return Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius, // Adjusted for better fit
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
