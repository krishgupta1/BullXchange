import 'package:bullxchange/services/firebase/fund_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import QR package

class AddFundPage extends StatefulWidget {
  const AddFundPage({super.key});

  @override
  State<AddFundPage> createState() => _AddFundPageState();
}

class _AddFundPageState extends State<AddFundPage> {
  // --- CONFIGURATION ---
  // REPLACE THIS WITH YOUR ACTUAL UPI ID (e.g., merchant@okicici, 9876543210@paytm)
  final String _myUpiId = "9336772455-6@ybl";
  final String _myName = "Bullxchange";

  final TextEditingController _coinController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();

  final FundService _fundService = FundService();

  double _calculatedPrice = 0.0;
  bool _isSubmitting = false;

  final double _coinsPerBatch = 10000;
  final double _pricePerBatch = 14.0;
  final List<int> _frequentOptions = [10000, 20000, 50000, 100000];

  @override
  void dispose() {
    _coinController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  void _calculatePrice(String value) {
    if (value.isEmpty) {
      setState(() => _calculatedPrice = 0.0);
      return;
    }
    String cleanValue = value.replaceAll(',', '');
    int? coins = int.tryParse(cleanValue);
    if (coins != null) {
      setState(() {
        _calculatedPrice = (coins / _coinsPerBatch) * _pricePerBatch;
      });
    }
  }

  void _selectFrequentOption(int coins) {
    _coinController.text = coins.toString();
    _calculatePrice(coins.toString());
    _coinController.selection = TextSelection.fromPosition(
      TextPosition(offset: _coinController.text.length),
    );
  }

  // --- PAYMENT SHEET WITH DYNAMIC QR ---
  void _showPaymentBottomSheet() {
    // 1. Generate the UPI URL String
    // Format: upi://pay?pa=UPI_ID&pn=NAME&am=AMOUNT&cu=INR
    final String upiUrl =
        "upi://pay?pa=$_myUpiId&pn=$_myName&am=${_calculatedPrice.toStringAsFixed(2)}&cu=INR";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Scan to Pay",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Amount: ₹${_calculatedPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // --- DYNAMIC QR CODE ---
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: upiUrl, // The magic string
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "UPI ID: $_myUpiId",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // --- UTR INPUT ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter UTR / Reference No:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _utrController,
                  decoration: const InputDecoration(
                    hintText: "e.g. 325198410922",
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),

                // --- SUBMIT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      if (_utrController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter a valid UTR"),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _submitRequest();
                    },
                    child: const Text(
                      "Submit Payment Details",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);
    try {
      int coins = int.parse(_coinController.text.replaceAll(',', ''));

      await _fundService.submitFundRequest(
        amountInRupees: _calculatedPrice,
        coins: coins,
        utr: _utrController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Request Submitted! Wait for Admin Approval."),
          ),
        );
        _utrController.clear();
        _coinController.clear();
        setState(() => _calculatedPrice = 0.0);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Add Funds"), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Box
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
                        "Rate: 10,000 Coins = ₹14",
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

              // Input
              const Text("Enter Coin Amount"),
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
                  suffixText: "Coins",
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _frequentOptions.map((coins) {
                  return ActionChip(
                    label: Text("$coins"),
                    onPressed: () => _selectFrequentOption(coins),
                  );
                }).toList(),
              ),

              const Spacer(),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Payable:",
                    style: TextStyle(
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
              const SizedBox(height: 10),

              // Main Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_calculatedPrice > 0 && !_isSubmitting)
                      ? _showPaymentBottomSheet
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Pay ₹${_calculatedPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
