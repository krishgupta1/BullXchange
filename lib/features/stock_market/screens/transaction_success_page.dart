import 'dart:math'; // Import math for blast direction
import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; // 1. Import Confetti

// 2. Change to StatefulWidget to manage the controller
class TransactionSuccessPage extends StatefulWidget {
  final TransactionModel transaction;
  final String transactionId;

  const TransactionSuccessPage({
    super.key,
    required this.transaction,
    required this.transactionId,
  });

  @override
  State<TransactionSuccessPage> createState() => _TransactionSuccessPageState();
}

class _TransactionSuccessPageState extends State<TransactionSuccessPage> {
  // 3. Declare the ConfettiController
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // 4. Initialize and set duration (how long the blast lasts)
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // 5. Play the animation immediately when page loads
    _confettiController.play();
  }

  @override
  void dispose() {
    // 6. Dispose the controller to free resources
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Access properties via widget.variableName now
    final bool isBuy = widget.transaction.transactionType == 'BUY';
    final String actionText = isBuy ? "purchased" : "sold";
    final String stockQuantity = widget.transaction.quantity.toString();
    final String companyName = widget.transaction.companyName;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // 7. Use a Stack to put Confetti ON TOP of your content
      body: Stack(
        children: [
          // --- EXISTING CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  Center(
                    child: Image.asset(
                      'assets/images/transaction_success.png',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const Icon(
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
                            transaction: widget.transaction,
                            transactionId: widget.transactionId,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "Order Details",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),

          // --- ⭐️ 8. CONFETTI WIDGET ---
          Align(
            alignment: Alignment.topCenter, // Confetti falls from top
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // 3.14 / 2 = 90 degrees (Straight Down)
              maxBlastForce: 5, // Speed
              minBlastForce: 2,
              emissionFrequency: 0.05, // How often particles are emitted
              numberOfParticles: 20, // Quantity per emission
              gravity: 0.2, // How fast they fall
              shouldLoop: false, // Play once then stop
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
              ], // Custom colors
            ),
          ),
        ],
      ),
    );
  }
}
