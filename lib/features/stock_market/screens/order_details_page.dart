import 'package:bullxchange/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatelessWidget {
  final TransactionModel transaction;
  final String transactionId;

  const OrderDetailsPage({
    super.key,
    required this.transaction,
    required this.transactionId,
  });

  // --- ⭐️ REMOVED HARDCODED COLORS ---

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final priceFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final bool isBuy = transaction.transactionType == 'BUY';
    final Color typeColor = isBuy ? const Color(0xFF1EAB58) : Colors.red;

    final bool isMarketOrder = transaction.orderType == 'Market';
    final String orderTypeLabel = isMarketOrder ? 'Market' : 'Limit';
    final String priceLabel = isMarketOrder ? 'Avg. Price' : 'Order Price';

    final String nseOrderId = "240${transactionId.hashCode.abs()}";

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'Order details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.quantity} Shares',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                // --- ⭐️ MODIFIED: Theme text color ---
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // --- ⭐️ MODIFIED: Theme border and surface color ---
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction.companyName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          // --- ⭐️ MODIFIED: Theme text color ---
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.transactionType,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceFormatter.format(transaction.totalAmount),
                    style: TextStyle(
                      fontSize: 10,
                      // --- ⭐️ MODIFIED: Theme grey color ---
                      color: textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(
                    context, // ⭐️ Pass context
                    'Order',
                    orderTypeLabel,
                    priceLabel,
                    priceFormatter.format(transaction.price),
                  ),
                  _buildDetailRow(
                    context, // ⭐️ Pass context
                    'Type',
                    transaction.productType,
                    'Exchange',
                    transaction.exchange,
                  ),
                  _buildDetailRow(
                    context, // ⭐️ Pass context
                    'Charges',
                    priceFormatter.format(transaction.charges),
                    'Avg Price',
                    priceFormatter.format(transaction.price),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Text(
                        'Order ID: $nseOrderId',
                        style: TextStyle(
                          color: textTheme.bodySmall?.color,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCopyIcon(context, transactionId), // ⭐️ Pass context
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ORDER STATUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                // --- ⭐️ MODIFIED: Theme grey color ---
                color: textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusStep(
              context: context, // ⭐️ Pass context
              title: 'Request Verified',
              subtitle: 'Bullxchange ID: ${transaction.userId}',
              idToCopy: transactionId,
              isFirst: true,
            ),
            _buildStatusStep(
              context: context, // ⭐️ Pass context
              title: 'Order Placed with ${transaction.exchange}',
              subtitle: '${transaction.exchange} Order ID: $nseOrderId',
              idToCopy: nseOrderId,
            ),
            _buildStatusStep(
              context: context, // ⭐️ Pass context
              title: 'Order Executed',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, // ⭐️ Added context
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  style: TextStyle(
                    color: textTheme.bodySmall?.color,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value1,
                  style: TextStyle(
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  style: TextStyle(
                    color: textTheme.bodySmall?.color,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value2,
                  style: TextStyle(
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep({
    required BuildContext context, // ⭐️ Added context
    required String title,
    String? subtitle,
    String? idToCopy,
    bool isFirst = false,
    bool isLast = false,
  }) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 1, height: 12, color: const Color(0xFF1EAB58)),
            const Icon(Icons.check_circle, color: Color(0xFF1EAB58), size: 20),
            if (!isLast)
              Container(
                width: 1,
                height: 48, // Adjust height as needed
                color: const Color(0xFF1EAB58),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            // --- ⭐️ MODIFIED: Theme grey color ---
                            color: textTheme.bodySmall?.color,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (idToCopy != null)
                        _buildCopyIcon(context, idToCopy), // ⭐️ Pass context
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyIcon(BuildContext context, String textToCopy) {
    // ⭐️ Added context
    // --- ⭐️ Theme se colors lo ---
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: textToCopy));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order ID copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        // --- ⭐️ MODIFIED: Theme grey color ---
        child: Icon(Icons.copy, color: textTheme.bodySmall?.color, size: 16),
      ),
    );
  }
}



