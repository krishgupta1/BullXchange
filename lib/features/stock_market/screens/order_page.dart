import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  void _handleCancelAll(BuildContext context) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel All Orders?'),
        content: const Text(
          'Are you sure you want to cancel all pending orders?',
        ),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text(
              'Yes, Cancel All',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final UserService userService = UserService();
      await userService.cancelAllOrders(uid);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All pending orders have been cancelled.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling orders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser?.uid == null) {
      return const Center(child: Text("Please log in to see your orders."));
    }

    return Consumer2<List<OrderModel>, InstrumentProvider>(
      builder: (context, openOrders, provider, child) {
        if (openOrders.isEmpty) {
          return const Center(child: _EmptyState());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Open orders (${openOrders.length})",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // ⭐️ REMOVED: Icon(Icons.keyboard_arrow_up)
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () => _handleCancelAll(context),
                      ),
                      Text(
                        "Qty/Price",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            ...openOrders.map((order) {
              final instrument = provider.getInstrumentByToken(
                order.instrumentToken,
              );

              return _buildOrderItem(
                context: context, // Passed context for navigation
                instrument: instrument,
                order: order,
              );
            }),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "No Pending Orders",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
  required BuildContext context,
  required Instrument? instrument,
  required OrderModel order,
}) {
  final ltp = (instrument?.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final orderType = order.transactionType;
  final quantity = order.quantity;

  final String priceText;
  if (order.orderType == 'LIMIT') {
    priceText = "At ₹${order.limitPrice.toStringAsFixed(2)}";
  } else {
    priceText = "Market";
  }

  // ⭐️ ADDED: InkWell for navigation
  return InkWell(
    onTap: () {
      // Map OrderModel to TransactionModel for the details page
      // Since it's a pending order, we use current values or placeholders for realized amounts
      final transactionData = TransactionModel(
        userId: order.userId,
        companyName: order.companyName,
        transactionType: order.transactionType,
        quantity: order.quantity,
        price: order.limitPrice > 0 ? order.limitPrice : ltp,
        charges: 0.0, // Estimated or 0 for pending
        totalAmount:
            (order.limitPrice > 0 ? order.limitPrice : ltp) * order.quantity,
        exchange: order.exchange,
        productType: order.productType,
        orderType: order.orderType,
        stockSymbol: order.symbol,
        transactionTime: order.createdAt,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsPage(
            transaction: transactionData,
            transactionId: "PENDING", // Or use order.id if available
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          instrument != null
              ? SmartLogo(instrument: instrument, radius: 20)
              : _buildLogoContainer(order.companyName, radius: 20),
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order.productType,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                "$quantity",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                priceText,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildLogoContainer(String name, {double radius = 20}) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
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
          fontSize: radius,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
