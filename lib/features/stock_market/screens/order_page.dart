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
import 'package:intl/intl.dart';

// --- HELPER: Transaction Type Badge (BUY/SELL) ---
Widget _buildTransactionBadge(BuildContext context, String type) {
  final isBuy = type == 'BUY';
  final color = isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3D00);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    ),
    child: Text(
      type,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// --- HELPER: Product Type Badge (INTRADAY/DELIVERY) ---
Widget _buildProductBadge(BuildContext context, String productType) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 10, color: Colors.blue),
        const SizedBox(width: 3),
        Text(
          productType.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  Future<void> _handleCancelAll(BuildContext context) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (auth.currentUser?.uid == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              "Please log in to see your orders.",
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Consumer2<List<OrderModel>, InstrumentProvider>(
      builder: (context, openOrders, provider, child) {
        if (openOrders.isEmpty) {
          return const Center(child: _EmptyState());
        }

        // Calculate total pending value for summary card
        double totalPendingValue = 0;
        for (var order in openOrders) {
          final price = order.limitPrice > 0 ? order.limitPrice : 0.0;
          totalPendingValue += (price * order.quantity);
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Summary Card
              _buildOrderSummaryCard(
                context,
                totalPendingValue,
                openOrders.length,
                onCancelAll: () => _handleCancelAll(context),
              ),

              // 2. Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pending Orders (${openOrders.length})",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Icon(Icons.sort, size: 20, color: Colors.grey),
                  ],
                ),
              ),

              // 3. Orders List
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: openOrders.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 72,
                  endIndent: 16,
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
                itemBuilder: (context, index) {
                  final order = openOrders[index];
                  final instrument = provider.getInstrumentByToken(
                    order.instrumentToken,
                  );
                  return _OrderListItem(order: order, instrument: instrument);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummaryCard(
    BuildContext context,
    double totalPendingValue,
    int orderCount, {
    required VoidCallback onCancelAll,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // --- UPDATED COLOR LOGIC FOR "ACTIVE" BADGE ---
    // Instead of using 'primary' which might be dark, we use a bright Blue Accent for Dark Mode.
    final activeTextColor = isDark
        ? Colors.blueAccent.shade100
        : Colors.blue.shade700;
    final activeBgColor = isDark
        ? Colors.blueAccent.withValues(alpha: 0.2)
        : Colors.blue.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.1 : 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Pending Value",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${totalPendingValue.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // --- ACTIVE BADGE ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: activeBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$orderCount Active",
                  style: TextStyle(
                    color: activeTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Action",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onCancelAll,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Cancel All",
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final OrderModel order;
  final Instrument? instrument;

  const _OrderListItem({required this.order, this.instrument});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ltp = (instrument?.liveData['ltp'] as num?)?.toDouble() ?? 0.0;

    final priceFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    String triggerPriceText = order.orderType == 'LIMIT'
        ? priceFormatter.format(order.limitPrice)
        : "Market";

    return InkWell(
      onTap: () {
        final transactionData = TransactionModel(
          userId: order.userId,
          companyName: order.companyName,
          transactionType: order.transactionType,
          quantity: order.quantity,
          price: order.limitPrice > 0 ? order.limitPrice : ltp,
          charges: 0.0,
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
              transactionId: "PENDING",
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            if (instrument != null)
              SmartLogo(instrument: instrument!, radius: 20)
            else
              _buildLogoContainer(order.companyName, theme),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTransactionBadge(context, order.transactionType),
                      const SizedBox(width: 6),
                      _buildProductBadge(context, order.productType),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  triggerPriceText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "LTP ${ltp == 0.0 ? '--' : priceFormatter.format(ltp)}",
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "• ${order.quantity} Qty",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildLogoContainer(String name, ThemeData theme) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? color.withRed(255).withGreen(255)
                : color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: theme.disabledColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "No Pending Orders",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your open orders will appear here.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
