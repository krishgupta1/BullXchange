import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/models/order_model.dart'; // <-- 1. IMPORT NEW MODEL
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';

class BuyStockPage extends StatefulWidget {
  final Instrument instrument;
  const BuyStockPage({super.key, required this.instrument});

  @override
  State<BuyStockPage> createState() => _BuyStockPageState();
}

class _BuyStockPageState extends State<BuyStockPage> {
  final _quantityController = TextEditingController();
  final _limitPriceController =
      TextEditingController(); // <-- 2. ADD PRICE CONTROLLER

  String _selectedProductType = 'Delivery';
  String _selectedExchange = 'NSE';
  String _selectedOrderType = 'Market'; // <-- 3. ADD ORDER TYPE

  Map<String, double> _chargesBreakdown = {};
  double _totalCharges = 0.0;

  double _totalAmount = 0.0;
  int _quantity = 0;
  late double _ltp;
  double _price = 0.0; // <-- 4. ADD PRICE STATE

  final UserService _userService = UserService();
  final ChargeCalculatorService _chargeCalculator = ChargeCalculatorService();
  bool _isPlacingOrder = false;

  static const Color primaryPink = Color(0xFFF61C7A);
  static const Color darkTextColor = Color(0xFF03314B);
  static const Color lightGreyBg = Color(0xFFF5F5F5);
  static const Color lightBorderColor = Color(0xFFE0E0E0);

  final _priceFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    _price = _ltp; // 5. Init price to LTP
    _limitPriceController.text = _ltp.toStringAsFixed(2);

    _quantityController.addListener(_calculateTotal);
    _limitPriceController.addListener(_onPriceChanged); // 6. Add listener
    _calculateTotal();
  }

  void _onPriceChanged() {
    if (_selectedOrderType == 'Limit') {
      setState(() {
        _price = double.tryParse(_limitPriceController.text) ?? 0.0;
        _calculateTotal();
      });
    }
  }

  void _onOrderTypeChanged(String newType) {
    setState(() {
      _selectedOrderType = newType;
      if (newType == 'Market') {
        _price = _ltp; // Set price to Market
        _limitPriceController.text = _ltp.toStringAsFixed(2);
      } else {
        _price = double.tryParse(_limitPriceController.text) ?? _ltp;
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _quantity = int.tryParse(_quantityController.text) ?? 0;
    final double tradeValue = _quantity * _price; // <-- Use _price not _ltp

    _chargesBreakdown = _chargeCalculator.calculateBuyCharges(tradeValue);
    _totalCharges = _chargesBreakdown['total'] ?? 0.0;

    _totalAmount = (_quantity > 0) ? (tradeValue + _totalCharges) : 0.0;
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotal);
    _limitPriceController.removeListener(_onPriceChanged);
    _quantityController.dispose();
    _limitPriceController.dispose();
    super.dispose();
  }

  // --- 7. UPDATED _handleBuy TO BE A ROUTER ---
  Future<void> _handleBuy() async {
    if (_quantity <= 0 || _price <= 0 || _isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // ... (error handling)
      setState(() => _isPlacingOrder = false);
      return;
    }

    if (_selectedOrderType == 'Market') {
      await _executeMarketOrder(uid);
    } else {
      await _placeLimitOrder(uid);
    }

    if (mounted) {
      setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _executeMarketOrder(String uid) async {
    final now = DateTime.now();
    final symbol = widget.instrument.symbol.replaceAll('-EQ', '');

    final newTransaction = TransactionModel(
      userId: uid,
      symbol: symbol,
      companyName: widget.instrument.name,
      transactionType: 'BUY',
      quantity: _quantity,
      price: _price, // Use _price (which is _ltp for market)
      charges: _totalCharges,
      totalAmount: _totalAmount,
      executedAt: now,
      exchange: _selectedExchange,
      productType: _selectedProductType,
    );

    final holdingUpdate = StockHoldingModel(
      stockName: widget.instrument.name,
      stockSymbol: symbol,
      quantity: _quantity,
      transactionPrice: _price,
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
      // ... (error handling)
    }
  }

  Future<void> _placeLimitOrder(String uid) async {
    final symbol = widget.instrument.symbol.replaceAll('-EQ', '');

    final newOrder = OrderModel(
      userId: uid,
      symbol: symbol,
      companyName: widget.instrument.name,
      transactionType: 'BUY',
      orderType: 'LIMIT',
      productType: _selectedProductType.toUpperCase(),
      quantity: _quantity,
      limitPrice: _price, // Use _price (the user's limit price)
      createdAt: DateTime.now(),
      exchange: _selectedExchange,
      instrumentToken: widget.instrument.token,
    );

    try {
      await _userService.placeLimitOrder(newOrder);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Limit order for $symbol placed successfully.'),
        ),
      );
      if (mounted) {
        // Go back to the main app screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // ... (error handling)
    }
  }

  // --- 8. UPDATED UI ---
  @override
  Widget build(BuildContext context) {
    // ... (Scaffold, AppBar, etc. are the same)
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
          'Buy ${widget.instrument.symbol.replaceAll('-EQ', '')}',
          style: const TextStyle(
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
            _buildStockHeader(_priceFormatter),
            const SizedBox(height: 24),
            _buildInputSection(), // This function is now updated
            const SizedBox(height: 24),
            _buildOrderSummary(
              _priceFormatter,
            ), // This function is also updated
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBuyButton(),
    );
  }

  Widget _buildStockHeader(NumberFormat formatter) {
    // ... (This function is unchanged)
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
                          color: Colors.grey,
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

  // --- 9. UPDATED _buildInputSection ---
  Widget _buildInputSection() {
    bool isLimit = _selectedOrderType == 'Limit';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSegmentedControl(
                title: 'Type',
                options: ['Market', 'Limit'],
                selectedValue: _selectedOrderType,
                onChanged: _onOrderTypeChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: lightBorderColor,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryPink,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _limitPriceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                enabled: isLimit, // <-- ONLY ENABLED FOR LIMIT
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLimit
                      ? darkTextColor
                      : Colors.grey, // <-- Visual cue
                ),
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: lightBorderColor,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryPink,
                      width: 2.0,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    // <-- Style for disabled
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSegmentedControl(
          title: 'Product',
          options: ['Delivery', 'Intraday'],
          selectedValue: _selectedProductType,
          onChanged: (value) => setState(() => _selectedProductType = value),
        ),
        const SizedBox(height: 20),
        _buildSegmentedControl(
          title: 'Exchange',
          options: ['NSE', 'BSE'],
          selectedValue: _selectedExchange,
          onChanged: (value) => setState(() => _selectedExchange = value),
        ),
      ],
    );
  }

  // ... (SegmentedControl is unchanged)
  Widget _buildSegmentedControl({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    // ... (This function is unchanged)
    return Row(
      children: [
        Text(
          '$title:',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
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
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryPink : Colors.transparent,
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
    );
  }

  // --- 10. UPDATED _buildOrderSummary ---
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
          // --- Updated Price Row ---
          _buildSummaryRow(
            'Price',
            _selectedOrderType == 'Market'
                ? 'Market'
                : formatter.format(_price),
          ),
          const Divider(height: 24),
          _buildSummaryRow('Subtotal', formatter.format(_quantity * _price)),
          // --- Charges Row (unchanged) ---
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
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () => _showChargeDetailsBottomSheet(context),
                    ),
                  ],
                ),
                Text(
                  formatter.format(_totalCharges),
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

  // ... (rest of the file is unchanged)
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
              color: isTotal ? darkTextColor : Colors.grey,
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

  Widget _buildBottomBuyButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: ElevatedButton(
        onPressed: (_quantity > 0 && _price > 0 && !_isPlacingOrder)
            ? _handleBuy
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          disabledBackgroundColor: Colors.pink.shade100,
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
                "Place Buy Order",
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
                'Buy Charges Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildChargeRow('Brokerage', _chargesBreakdown['brokerage']),
              _buildChargeRow('STT (Buy)', _chargesBreakdown['stt']),
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
