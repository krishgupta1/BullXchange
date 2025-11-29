import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';

import 'package:bullxchange/models/transaction_model.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

class TransactionSuccessPage extends StatelessWidget {
  final TransactionModel transaction;
  final String transactionId;

  const TransactionSuccessPage({
    super.key,
    required this.transaction,
    required this.transactionId,
  });

  // --- ⭐️ REMOVED HARDCODED COLORS ---
  // static const Color primaryPurple = ...
  // static const Color darkTextColor = ...

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // (Logic unchanged)
    final bool isBuy = transaction.transactionType == 'BUY';
    final String actionText = isBuy ? "purchased" : "sold";
    final String stockQuantity = transaction.quantity.toString();
    final String companyName = transaction.companyName;

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Keep the original intent of removing back navigation where used
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Illustration
              Center(
                child: Image.asset(
                  'assets/images/transaction_success.png',
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      // --- ⭐️ MODIFIED: Fallback icon ---
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 150,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Transaction Complete",
                textAlign: TextAlign.center,
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You $actionText $stockQuantity stocks of $companyName.",
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  // --- ⭐️ MODIFIED: Theme button color (Blue) ---
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Go to Home",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsPage(
                        transaction: transaction,
                        transactionId: transactionId,
                      ),
                    ),
                  );
                },
                child: Text(
                  "Order Details",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    // --- ⭐️ MODIFIED: Theme accent color (Pink) ---
                    color: colorScheme.secondary,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
