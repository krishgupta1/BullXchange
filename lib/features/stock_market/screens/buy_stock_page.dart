import 'dart:math';
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
  String _selectedProductType = 'Delivery';
  String _selectedExchange = 'NSE';
  double _charges = 0.0;
  double _totalAmount = 0.0;
  int _quantity = 0;
  late double _ltp;
  final UserService _userService = UserService();
  bool _isPlacingOrder = false;
  static const Color primaryPink = Color(0xFFF61C7A);
  static const Color darkTextColor = Color(0xFF03314B);
  static const Color lightGreyBg = Color(0xFFF5F5F5);
  static const Color lightBorderColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    _generateRandomCharges();
    _quantityController.addListener(_calculateTotal);
  }

  void _generateRandomCharges() {
    _charges = 5.0 + Random().nextDouble() * 20.0;
  }

  void _calculateTotal() {
    setState(() {
      _quantity = int.tryParse(_quantityController.text) ?? 0;
      _totalAmount = (_quantity > 0) ? (_quantity * _ltp) + _charges : 0.0;
    });
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotal);
    _quantityController.dispose();
    super.dispose();
  }

  // --- THIS METHOD IS CORRECTED ---
  Future<void> _handleBuy() async {
    if (_quantity <= 0 || _isPlacingOrder) return;
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

    // Model for updating the user's HOLDINGS (the summary)
    final holdingUpdate = StockHoldingModel(
      stockName: widget.instrument.name,
      stockSymbol: symbol,
      quantity: _quantity,
      transactionPrice: _ltp,
      buyingTime: now,
      charges: _charges,
      totalAmount: _totalAmount,
      exchange: _selectedExchange,
      transactionType: _selectedProductType.toUpperCase(),
    );

    // Model for logging the individual TRANSACTION
    final newTransaction = TransactionModel(
      userId: uid,
      symbol: symbol,
      companyName: widget.instrument.name,
      transactionType: 'BUY',
      quantity: _quantity,
      price: _ltp,
      charges: _charges,
      totalAmount: _totalAmount,
      executedAt: now,
    );

    try {
      // --- MODIFIED: Use the single atomic executeTrade function ---
      await _userService.executeTrade(
        uid: uid,
        transaction: newTransaction,
        stockHoldingUpdate: holdingUpdate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Successfully bought $_quantity shares of $symbol.'),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  // --- (Rest of the UI code is unchanged and correct) ---
  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
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
            _buildStockHeader(priceFormatter),
            const SizedBox(height: 24),
            _buildInputSection(),
            const SizedBox(height: 24),
            _buildOrderSummary(priceFormatter),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBuyButton(),
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
                SmartLogo(instrument: widget.instrument),
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

  Widget _buildInputSection() {
    return Column(
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
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightBorderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryPink, width: 2.0),
            ),
          ),
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

  Widget _buildSegmentedControl({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
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
          _buildSummaryRow('Charges', formatter.format(_charges)),
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
        onPressed: (_quantity > 0 && !_isPlacingOrder) ? _handleBuy : null,
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
}
