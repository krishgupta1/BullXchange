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

  // Using the purple color from the screenshot
  static const Color primaryPurple = Color(0xFF4F46E5);
  static const Color darkTextColor = Color(0xFF03314B);

  @override
  Widget build(BuildContext context) {
    // final priceFormatter = NumberFormat.currency(
    //   locale: 'en_IN',
    //   symbol: '₹',
    //   decimalDigits: 2,
    // );

    final bool isBuy = transaction.transactionType == 'BUY';
    final String actionText = isBuy ? "purchased" : "sold";
    final String stockQuantity = transaction.quantity.toString();
    // final String amountText = priceFormatter.format(transaction.totalAmount);
    final String companyName = transaction.companyName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Removes back arrow
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Illustration - Using a placeholder icon
              Center(
                child: Image.asset(
                  'assets/images/transaction_success.png', // Placeholder for your illustration
                  height: 200,
                  // If you don't have an image, use an icon:
                  // child: Icon(
                  //   Icons.check_circle_outline,
                  //   color: Colors.green,
                  //   size: 150,
                  // ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Transaction Complete",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You $actionText $stockQuantity stocks of $companyName.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () {
                  // Pops all routes until the first one (usually your home screen)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Go to Home",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Navigate to the Order Details page
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
                child: const Text(
                  "Order Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryPurple,
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
