import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';

class SellStockPage extends StatefulWidget {
  final Instrument instrument;
  final StockHoldingModel userHolding;
  const SellStockPage({
    super.key,
    required this.instrument,
    required this.userHolding,
  });

  @override
  State<SellStockPage> createState() => _SellStockPageState();
}

class _SellStockPageState extends State<SellStockPage> {
  // --- UI Constants ---
  static const Color primaryBlue = Color(0xFF3500D4);
  static const Color darkTextColor = Color(0xFF03314B);
  static const Color lightGreyBg = Color(0xFFF5F5F5);
  static const Color lightBorderColor = Color(0xFFE0E0E0);
  static const Color secondaryTextColor = Color(0xFF6A7584);
  // ---

  final _quantityController = TextEditingController();
  String _selectedProductType = 'Delivery';
  String _selectedExchange = 'NSE';

  Map<String, double> _chargesBreakdown = {};
  double _totalCharges = 0.0;

  double _totalAmount = 0.0;
  int _quantity = 0;
  late double _ltp;
  late int _ownedQuantity;
  String? _errorText;

  final UserService _userService = UserService();
  final ChargeCalculatorService _chargeCalculator = ChargeCalculatorService();
  bool _isPlacingOrder = false;

  final _priceFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    _ownedQuantity = widget.userHolding.quantity;
    _selectedExchange = widget.userHolding.exchange;
    _selectedProductType = widget.userHolding.transactionType == 'DELIVERY'
        ? 'Delivery'
        : 'Intraday';
    _quantityController.addListener(_calculateTotalAndValidate);
    _calculateTotalAndValidate();
  }

  void _calculateTotalAndValidate() {
    setState(() {
      _quantity = int.tryParse(_quantityController.text) ?? 0;
      _errorText = (_quantity > _ownedQuantity)
          ? 'Quantity cannot exceed holdings ($_ownedQuantity)'
          : null;

      final double tradeValue = _quantity * _ltp;

      _chargesBreakdown = _chargeCalculator.calculateSellCharges(tradeValue);
      _totalCharges = _chargesBreakdown['total'] ?? 0.0;

      _totalAmount = (_quantity > 0) ? (tradeValue - _totalCharges) : 0.0;
    });
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotalAndValidate);
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _handleSell() async {
    if (_quantity <= 0 || _isPlacingOrder || _errorText != null) return;
    setState(() => _isPlacingOrder = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in.')),
      );
      setState(() => _isPlacingOrder = false);
      return;
    }

    final now = DateTime.now();
    final symbol = widget.instrument.symbol.replaceAll('-EQ', '');

    final newTransaction = TransactionModel(
      userId: uid,
      symbol: symbol,
      companyName: widget.instrument.name,
      transactionType: 'SELL',
      quantity: _quantity,
      price: _ltp,
      charges: _totalCharges,
      totalAmount: _totalAmount,
      executedAt: now,
      exchange: _selectedExchange,
      productType: _selectedProductType,
      orderType: 'Market', // Sell is always a Market order in this flow
    );

    final holdingUpdate = StockHoldingModel(
      stockName: widget.instrument.name,
      stockSymbol: symbol,
      quantity: -_quantity, // Negative quantity for selling
      transactionPrice: _ltp,
      buyingTime: now,
      charges: _totalCharges,
      totalAmount: _totalAmount,
      exchange: _selectedExchange,
      transactionType: _selectedProductType.toUpperCase(),
    );

    try {
      final String transactionId = await _userService.executeTrade(
        uid: uid,
        transaction: newTransaction,
        stockHoldingUpdate: holdingUpdate,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => TransactionSuccessPage(
              transaction: newTransaction,
              transactionId: transactionId,
            ),
          ),
          (route) => route.isFirst, // Clears stack back to home
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ ADDED AUTH CHECK ---
    final auth = FirebaseAuth.instance;
    if (auth.currentUser?.uid == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Sell Stock',
            style: TextStyle(
              color: darkTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: Text("Please log in to sell stocks.")),
      );
    }
    // --- END OF CHECK ---

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
        title: Text(
          'Sell ${widget.instrument.symbol.replaceAll('-EQ', '')}',
          style: const TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      // --- ⭐️ SOLUTION: HYBRID SCROLLING BODY ---
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStockHeader(_priceFormatter),
                  const SizedBox(height: 16), // --- MODIFIED ---
                  _buildInputSection(),
                  const SizedBox(height: 16), // --- MODIFIED ---
                  _buildOrderSummary(_priceFormatter),
                  // Add padding at the bottom for scroll comfort
                  const SizedBox(height: 10), // --- MODIFIED ---
                ],
              ),
            ),
          ),
        ],
      ),

      // --- END OF SOLUTION ---
      bottomNavigationBar: _buildBottomSellButton(),
    );
  }

  Widget _buildStockHeader(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGreyBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                SmartLogo(instrument: widget.instrument, radius: 0),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.instrument.symbol.replaceAll('-EQ', ''),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkTextColor,
                        ),
                      ),
                      Text(
                        widget.instrument.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatter.format(_ltp),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkTextColor,
          ),
          decoration: InputDecoration(
            labelText: 'Quantity',
            errorText: _errorText,
            labelStyle: const TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightBorderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
            'You own: $_ownedQuantity shares',
            style: const TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16), // --- MODIFIED ---
        _buildSegmentedControl(
          title: 'Product',
          options: ['Delivery', 'Intraday'],
          selectedValue: _selectedProductType,
          onChanged: (value) {},
          isEnabled: false,
        ),
        const SizedBox(height: 16), // --- MODIFIED ---
        _buildSegmentedControl(
          title: 'Exchange',
          options: ['NSE', 'BSE'],
          selectedValue: _selectedExchange,
          onChanged: (value) {},
          isEnabled: false,
        ),
      ],
    );
  }

  Widget _buildSegmentedControl({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    bool isEnabled = true,
    Color? activeColor, // Optional active color
  }) {
    final color = activeColor ?? primaryBlue;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Text(
            '$title:',
            style: const TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: lightGreyBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: options.map((option) {
                bool isSelected = selectedValue == option;
                return GestureDetector(
                  onTap: () => isEnabled ? onChanged(option) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isEnabled ? color : Colors.grey)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : darkTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightBorderColor, width: 1.5),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Quantity', _quantity.toString()),
          _buildSummaryRow('Price', formatter.format(_ltp)),
          const Divider(height: 24),
          _buildSummaryRow('Subtotal', formatter.format(_quantity * _ltp)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Charges',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: secondaryTextColor,
                        size: 18,
                      ),
                      onPressed: () => _showChargeDetailsBottomSheet(context),
                    ),
                  ],
                ),
                Text(
                  "-${formatter.format(_totalCharges)}", // Note the minus sign
                  style: TextStyle(
                    fontSize: 16,
                    color: darkTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total Amount',
            formatter.format(_totalAmount),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isTotal ? darkTextColor : secondaryTextColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: darkTextColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSellButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // --- MODIFIED ---
      child: ElevatedButton(
        onPressed: (_quantity > 0 && !_isPlacingOrder && _errorText == null)
            ? _handleSell
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          disabledBackgroundColor: Colors.blue.shade100,
        ),
        child: _isPlacingOrder
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                "Place Sell Order",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showChargeDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sell Charges Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildChargeRow('Brokerage', _chargesBreakdown['brokerage']),
              _buildChargeRow('STT (Sell)', _chargesBreakdown['stt']),
              _buildChargeRow(
                'Exchange Charges',
                _chargesBreakdown['exchangeCharges'],
              ),
              _buildChargeRow('SEBI Charges', _chargesBreakdown['sebiCharges']),
              _buildChargeRow('Stamp Duty', _chargesBreakdown['stampDuty']),
              _buildChargeRow('GST', _chargesBreakdown['gst']),
              const Divider(height: 24),
              _buildChargeRow(
                'Total Charges',
                _chargesBreakdown['total'],
                isTotal: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChargeRow(String label, double? value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isTotal ? darkTextColor : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            _priceFormatter.format(value ?? 0.0),
            style: TextStyle(
              fontSize: 16,
              color: darkTextColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
