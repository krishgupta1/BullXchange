import 'package:flutter/material.dart';
// Note: No provider, model, or Firebase imports are needed for this static UI.

// --- ⭐️ STATIC F&O ORDERS PAGE ---
class FutureOptionOrdersPage extends StatelessWidget {
  const FutureOptionOrdersPage({super.key});

  // --- ⭐️ Static "Cancel All" handler ---
  // (Shows a SnackBar for demo, has no real logic)
  void _handleCancelAll(BuildContext context) async {
    // --- Step 1: Show Confirmation Dialog ---
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel All F&O Orders?'),
        content: const Text(
          'Are you sure you want to cancel all pending F&O orders?',
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

    // --- Step 2: Show confirmation SnackBar (no real logic) ---
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All pending F&O orders would be cancelled.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ 1. Hardcoded data ---
    // Set to 'false' to see the empty state
    const bool hasOrders = true;

    if (!hasOrders) {
      return const Center(child: _EmptyState());
    }

    // --- ⭐️ 2. Re-create the Column structure from OrderPage ---
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Header Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Open F&O orders (2)", // Hardcoded count
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_up),
                ],
              ),
              const SizedBox(height: 16),
              // --- "Cancel All" Row ---
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
                    "Lots/Price", // Changed from Qty to Lots
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // --- ⭐️ 3. Static List of F&O Order Items ---
        _FnoOrderItem(
          symbol: "NIFTY 28NOV25 24500 CE",
          orderType: "BUY",
          productType: "NRML",
          lots: 2,
          lotSize: 50,
          priceText: "At ₹120.50",
          ltp: 142.75,
          logoLetter: "N",
          logoColor: Colors.blue.shade700,
        ),
        _FnoOrderItem(
          symbol: "BANKNIFTY 28NOV25 51000 PE",
          orderType: "SELL",
          productType: "MIS", // Intraday
          lots: 1,
          lotSize: 15,
          priceText: "Market",
          ltp: 280.40,
          logoLetter: "B",
          logoColor: Colors.red.shade700,
        ),
      ],
    );
  }
}

// --- ⭐️ STATIC F&O ORDER ITEM WIDGET ---
// (Styled to match your _buildOrderItem)
class _FnoOrderItem extends StatelessWidget {
  final String symbol;
  final String orderType;
  final String productType;
  final int lots;
  final int lotSize;
  final String priceText;
  final double ltp;
  final String logoLetter;
  final Color logoColor;

  const _FnoOrderItem({
    required this.symbol,
    required this.orderType,
    required this.productType,
    required this.lots,
    required this.lotSize,
    required this.priceText,
    required this.ltp,
    required this.logoLetter,
    required this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    final int totalQuantity = lots * lotSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // --- Logo ---
          _buildLogoContainer(logoLetter, color: logoColor, radius: 20),
          const SizedBox(width: 12),
          // --- Middle Column (Symbol/LTP) ---
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
                  symbol,
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
          // --- Right Column (Qty/Price) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                productType,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                "$lots Lots ($totalQuantity)",
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
    );
  }
}

// --- ⭐️ HELPER WIDGETS ---
// (Copied from your OrderPage code for identical style)

Widget _buildLogoContainer(String name, {double radius = 20, Color? color}) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
  final logoColor =
      color ?? Colors.primaries[name.hashCode % Colors.primaries.length];
  return Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(color: logoColor, shape: BoxShape.circle),
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
          "No Pending F&O Orders",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Your open F&O orders for the day will appear here.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
