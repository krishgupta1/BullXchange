import 'package:bullxchange/models/transaction_model.dart';
import 'package:flutter/material.dart';
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

  static const Color darkTextColor = Color(0xFF03314B);
  static const Color lightBorderColor = Color(0xFFE0E0E0);
  static const Color lightGreyBg = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final bool isBuy = transaction.transactionType == 'BUY';
    final Color typeColor = isBuy ? const Color(0xFF1EAB58) : Colors.red;

    // --- ⭐️ 1. AUTOMATE ORDER TYPE AND PRICE LABEL ---
    // This assumes you added `orderType` to your TransactionModel
    final bool isMarketOrder = transaction.orderType == 'Market';
    final String orderTypeLabel = isMarketOrder ? 'Market' : 'Limit';
    final String priceLabel = isMarketOrder ? 'Avg. Price' : 'Order Price';

    // Generate a placeholder NSE ID
    final String nseOrderId =
        "00${transaction.executedAt.millisecondsSinceEpoch.toString().substring(5)}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Order details',
          style: TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.quantity} Shares',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: darkTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: lightBorderColor),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkTextColor,
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceFormatter.format(transaction.totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 32),

                  // --- ⭐️ 2. USE THE AUTOMATED LABELS ---
                  _buildDetailRow(
                    'Order',
                    orderTypeLabel, // <-- Automated
                    priceLabel, // <-- Automated
                    priceFormatter.format(transaction.price),
                  ),

                  _buildDetailRow(
                    'Type',
                    transaction.productType, // From TransactionModel
                    'Exchange',
                    transaction.exchange, // From TransactionModel
                  ),
                  _buildDetailRow(
                    'Charges',
                    priceFormatter.format(transaction.charges),
                    'Avg Price', // This is always true for an executed order
                    priceFormatter.format(transaction.price),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Text(
                        'Order ID: $transactionId',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      _buildCopyIcon(context, transactionId),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ORDER STATUS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusStep(
              title: 'Request Verified',
              subtitle: 'Bullxchange ID: ${transaction.userId}',
              context: context,
              idToCopy: transactionId,
              isFirst: true,
            ),
            _buildStatusStep(
              title: 'Order Placed with ${transaction.exchange}',
              subtitle: '${transaction.exchange} Order ID: $nseOrderId',
              context: context,
              idToCopy: nseOrderId,
            ),
            _buildStatusStep(title: 'Order Executed', isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value1,
                  style: const TextStyle(
                    color: darkTextColor,
                    fontSize: 15,
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value2,
                  style: const TextStyle(
                    color: darkTextColor,
                    fontSize: 15,
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
    required String title,
    String? subtitle,
    String? idToCopy,
    BuildContext? context,
    bool isFirst = false,
    bool isLast = false,
  }) {
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: darkTextColor,
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
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (idToCopy != null && context != null)
                        _buildCopyIcon(context, idToCopy),
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
        child: Icon(Icons.copy, color: Colors.grey[500], size: 16),
      ),
    );
  }
}
