import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddFundPage extends StatefulWidget {
  const AddFundPage({super.key});

  @override
  State<AddFundPage> createState() => _AddFundPageState();
}

class _AddFundPageState extends State<AddFundPage> {
  final TextEditingController _coinController = TextEditingController();
  double _calculatedPrice = 0.0;

  // Conversion Rate: 10,000 coins = 14 RS
  final double _coinsPerBatch = 10000;
  final double _pricePerBatch = 14.0;

  // Frequent buy options
  final List<int> _frequentOptions = [10000, 20000, 50000, 100000];

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _calculatePrice(String value) {
    if (value.isEmpty) {
      setState(() => _calculatedPrice = 0.0);
      return;
    }

    // Remove commas if user pastes them
    String cleanValue = value.replaceAll(',', '');
    int? coins = int.tryParse(cleanValue);

    if (coins != null) {
      setState(() {
        // Formula: (Coins / 10000) * 14
        _calculatedPrice = (coins / _coinsPerBatch) * _pricePerBatch;
      });
    }
  }

  void _selectFrequentOption(int coins) {
    _coinController.text = coins.toString();
    _calculatePrice(coins.toString());
    // Move cursor to end
    _coinController.selection = TextSelection.fromPosition(
      TextPosition(offset: _coinController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Funds",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Info ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Conversion Rate: 10,000 Coins = ₹14",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- Input Field ---
              Text(
                "Enter Coin Amount",
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _coinController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                onChanged: _calculatePrice,
                decoration: InputDecoration(
                  hintText: "0",
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  suffixText: "Coins",
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- Frequent Options (Chips) ---
              Text(
                "Quick Select",
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _frequentOptions.map((coins) {
                  return ActionChip(
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    label: Text(
                      "$coins",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _selectFrequentOption(coins),
                  );
                }).toList(),
              ),

              const Spacer(),

              // --- Total Calculation Display ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Payable:",
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      "₹${_calculatedPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Pay Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _calculatedPrice > 0
                      ? () {
                          // TODO: Trigger Payment Gateway here
                          _initiatePayment();
                        }
                      : null, // Disable if 0
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Pay ₹${_calculatedPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _initiatePayment() {
    // Logic for payment gateway (Razorpay/PhonePe) goes here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Initiating payment for ₹${_calculatedPrice.toStringAsFixed(2)}",
        ),
      ),
    );
  }
}
