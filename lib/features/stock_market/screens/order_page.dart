import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- ⭐️ 1. IMPORT FIREBASE AND USER SERVICE ---
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  // --- ⭐️ 2. NEW METHOD TO HANDLE CANCELLATION ---
  void _handleCancelAll(BuildContext context) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    // --- Step 1: Show Confirmation Dialog ---
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

    if (confirm != true) return; // User pressed "No"

    // --- Step 2: Show Loading Dialog ---
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    // --- Step 3: Call Service ---
    try {
      final UserService userService = UserService();
      await userService.cancelAllOrders(uid);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All pending orders have been cancelled.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
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
    // --- ⭐️ ADDED AUTH CHECK ---
    final auth = FirebaseAuth.instance;
    if (auth.currentUser?.uid == null) {
      // Changed "holdings" to "orders" to match the page
      return const Center(child: Text("Please log in to see your orders."));
    }

    return Consumer2<List<OrderModel>, InstrumentProvider>(
      builder: (context, openOrders, provider, child) {
        if (openOrders.isEmpty) {
          // --- ⭐️ 3. WRAP EMPTY STATE IN A CENTER ---
          return const Center(child: _EmptyState());
        }

        // --- ⭐️ 4. RETURN A COLUMN, NOT A LISTVIEW ---
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_up),
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
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        onPressed: () => _handleCancelAll(context),
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

            // --- ⭐️ 5. SPREAD THE LIST OF WIDGETS DIRECTLY ---
            // This Column will be scrolled by its parent (SingleChildScrollView)
            ...openOrders.map((order) {
              final instrument = provider.getInstrumentByToken(
                order.instrumentToken,
              );

              return _buildOrderItem(instrument: instrument, order: order);
            }),
          ],
        );
      },
    );
  }
}

// --- Reusable Widgets (UNCHANGED) ---

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center vertically
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
  required Instrument? instrument,
  required OrderModel order,
}) {
  final ltp = (instrument?.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument?.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final changeColor = netChange >= 0 ? Colors.green : Colors.red;

  final orderType = order.transactionType;
  final quantity = order.quantity;

  final String priceText;
  if (order.orderType == 'LIMIT') {
    priceText = "At ₹${order.limitPrice.toStringAsFixed(2)}";
  } else {
    priceText = "Market";
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                        fontSize: 12,
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
                  fontSize: 12,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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