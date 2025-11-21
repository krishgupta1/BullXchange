import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/models/instrument_model.dart';

import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  // --- ⭐️ REMOVED HARDCODED COLORS ---

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

  // --- (initState, dispose, _calculateTotalAndValidate, _handleSell functions unchanged in logic) ---

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
      companyName: widget.instrument.name,
      transactionType: 'SELL',
      quantity: _quantity,
      price: _ltp,
      charges: _totalCharges,
      totalAmount: _totalAmount,
      exchange: _selectedExchange,
      productType: _selectedProductType,
      orderType: 'Market',
      stockSymbol: symbol,
      transactionTime: now, // Sell is always a Market order in this flow
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

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- AUTH CHECK ---
    final auth = FirebaseAuth.instance;
    if (auth.currentUser?.uid == null) {
      return Scaffold(
        // --- ⭐️ MODIFIED: Theme colors ---
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Sell Stock',
            style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            "Please log in to sell stocks.",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }
    // --- END OF CHECK ---

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // --- ⭐️ MODIFIED: Theme app bar colors ---
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              // --- ⭐️ MODIFIED: Theme surface color ---
              color: colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // --- ⭐️ MODIFIED: Theme shadow color ---
                  color: theme.shadowColor.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                // --- ⭐️ MODIFIED: Theme icon color ---
                color: colorScheme.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Sell ${widget.instrument.symbol.replaceAll('-EQ', '')}',
          // --- ⭐️ MODIFIED: Theme title style ---
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStockHeader(
                    context,
                    _priceFormatter,
                  ), // ⭐️ Pass context
                  const SizedBox(height: 16),
                  _buildInputSection(context), // ⭐️ Pass context
                  const SizedBox(height: 16),
                  _buildOrderSummary(
                    context,
                    _priceFormatter,
                  ), // ⭐️ Pass context
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomSellButton(context), // ⭐️ Pass context
    );
  }

  Widget _buildStockHeader(BuildContext context, NumberFormat formatter) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme surface color ---
        color: colorScheme.surface,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          // --- ⭐️ MODIFIED: Theme text color ---
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        widget.instrument.name,
                        style: TextStyle(
                          fontSize: 14,
                          // --- ⭐️ MODIFIED: Theme grey color ---
                          color: textTheme.bodySmall?.color,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // --- ⭐️ MODIFIED: Theme text color ---
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          // --- ⭐️ MODIFIED: Theme text color ---
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Quantity',
            errorText: _errorText,
            labelStyle: TextStyle(
              // --- ⭐️ MODIFIED: Theme grey color ---
              color: textTheme.bodySmall?.color,
              fontSize: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              // --- ⭐️ MODIFIED: Theme border color ---
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              // --- ⭐️ MODIFIED: Theme primary color ---
              borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error, width: 2.0),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
            'You own: $_ownedQuantity shares',
            style: TextStyle(
              // --- ⭐️ MODIFIED: Theme grey color ---
              color: textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSegmentedControl(
          context: context, // ⭐️ Pass context
          title: 'Product',
          options: ['Delivery', 'Intraday'],
          selectedValue: _selectedProductType,
          onChanged: (value) {},
          isEnabled: false,
        ),
        const SizedBox(height: 16),
        _buildSegmentedControl(
          context: context, // ⭐️ Pass context
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
    required BuildContext context, // ⭐️ Added context
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    bool isEnabled = true,
  }) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Text(
            '$title:',
            style: TextStyle(
              fontSize: 16,
              // --- ⭐️ MODIFIED: Theme grey color ---
              color: textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            height: 40,
            decoration: BoxDecoration(
              // --- ⭐️ MODIFIED: Theme surface color ---
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              // --- ⭐️ MODIFIED: Theme border ---
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
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
                          // --- ⭐️ MODIFIED: Theme primary color ---
                          ? (isEnabled
                                ? colorScheme.primary
                                : theme.disabledColor)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        // --- ⭐️ MODIFIED: Theme text colors ---
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
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

  Widget _buildOrderSummary(BuildContext context, NumberFormat formatter) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // --- ⭐️ MODIFIED: Theme border color ---
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            context,
            'Quantity',
            _quantity.toString(),
          ), // ⭐️ Pass context
          _buildSummaryRow(
            context,
            'Price',
            formatter.format(_ltp),
          ), // ⭐️ Pass context
          const Divider(height: 24),
          _buildSummaryRow(
            context,
            'Subtotal',
            formatter.format(_quantity * _ltp),
          ), // ⭐️ Pass context
          _buildChargesRow(context, formatter), // ⭐️ Pass context
          const Divider(height: 24),
          _buildSummaryRow(
            // ⭐️ Pass context
            context,
            'Total Amount',
            formatter.format(_totalAmount),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChargesRow(BuildContext context, NumberFormat formatter) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
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
                  color: textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: textTheme.bodySmall?.color,
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
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              // --- ⭐️ MODIFIED: Theme text/grey color ---
              color: isTotal
                  ? colorScheme.onSurface
                  : textTheme.bodySmall?.color,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              // --- ⭐️ MODIFIED: Theme text color ---
              color: colorScheme.onSurface,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSellButton(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // --- ⭐️ MODIFIED: Theme nav bar color ---
      color: theme.bottomNavigationBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ElevatedButton(
        onPressed: (_quantity > 0 && !_isPlacingOrder && _errorText == null)
            ? _handleSell
            : null,
        style: ElevatedButton.styleFrom(
          // --- ⭐️ MODIFIED: Theme primary color (Blue) ---
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          // --- ⭐️ MODIFIED: Theme disabled color ---
          disabledBackgroundColor: colorScheme.primary.withOpacity(0.3),
        ),
        child: _isPlacingOrder
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onPrimary,
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
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
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
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildChargeRow(
                context,
                'Brokerage',
                _chargesBreakdown['brokerage'],
              ),
              _buildChargeRow(context, 'STT (Sell)', _chargesBreakdown['stt']),
              _buildChargeRow(
                context,
                'Exchange Charges',
                _chargesBreakdown['exchangeCharges'],
              ),
              _buildChargeRow(
                context,
                'SEBI Charges',
                _chargesBreakdown['sebiCharges'],
              ),
              _buildChargeRow(
                context,
                'Stamp Duty',
                _chargesBreakdown['stampDuty'],
              ),
              _buildChargeRow(context, 'GST', _chargesBreakdown['gst']),
              const Divider(height: 24),
              _buildChargeRow(
                context,
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

  Widget _buildChargeRow(
    BuildContext context,
    String label,
    double? value, {
    bool isTotal = false,
  }) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              // --- ⭐️ MODIFIED: Theme text/grey color ---
              color: isTotal
                  ? colorScheme.onSurface
                  : textTheme.bodySmall?.color,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            _priceFormatter.format(value ?? 0.0),
            style: TextStyle(
              fontSize: 16,
              // --- ⭐️ MODIFIED: Theme text color ---
              color: colorScheme.onSurface,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
