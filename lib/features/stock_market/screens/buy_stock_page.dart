import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
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
  // --- ⭐️ REMOVED HARDCODED COLORS ---

  final _quantityController = TextEditingController();
  final _limitPriceController = TextEditingController();

  String _selectedProductType = 'Delivery';
  String _selectedExchange = 'NSE';
  String _selectedOrderType = 'Market';

  Map<String, double> _chargesBreakdown = {};
  double _totalCharges = 0.0;

  double _totalAmount = 0.0;
  int _quantity = 0;
  late double _ltp;
  double _price = 0.0;

  double _availableFunds = 0.0;
  bool _isLoadingFunds = true;

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
    _price = _ltp;
    _limitPriceController.text = _ltp.toStringAsFixed(2);

    _quantityController.addListener(_calculateTotal);
    _limitPriceController.addListener(_onPriceChanged);

    _fetchAvailableFunds();
    _calculateTotal();
  }

  // --- (initState, dispose, _fetchAvailableFunds, _onPriceChanged,
  //      _calculateTotal, _handleBuy, _executeMarketOrder,
  //      _placeLimitOrder functions are unchanged in logic) ---

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotal);
    _limitPriceController.removeListener(_onPriceChanged);
    _quantityController.dispose();
    _limitPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableFunds() async {
    setState(() => _isLoadingFunds = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final UserProfileDataModel? user = await _userService.readUserProfile(
          uid,
        );
        if (user != null && mounted) {
          setState(() {
            _availableFunds = user.availableFunds;
          });
        }
      }
    } catch (e) {
      print("Error fetching funds: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingFunds = false);
      }
    }
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
    setState(() {
      _quantity = int.tryParse(_quantityController.text) ?? 0;
      final double tradeValue = _quantity * _price;

      _chargesBreakdown = _chargeCalculator.calculateBuyCharges(tradeValue);
      _totalCharges = _chargesBreakdown['total'] ?? 0.0;

      _totalAmount = (_quantity > 0) ? (tradeValue + _totalCharges) : 0.0;
    });
  }

  Future<void> _handleBuy() async {
    if (_quantity <= 0 || _price <= 0 || _isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('User not logged in.'),
        ),
      );
      setState(() => _isPlacingOrder = false);
      return;
    }

    if (_totalAmount > _availableFunds) {
      if (mounted) {
        _showInsufficientFundsDialog(context, _availableFunds, _totalAmount);
      }
      setState(() => _isPlacingOrder = false);
      return;
    }

    try {
      if (_selectedOrderType == 'Market') {
        await _executeMarketOrder(uid);
      } else {
        await _placeLimitOrder(uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('An error occurred: ${e.toString()}'),
          ),
        );
      }
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
      price: _price,
      charges: _totalCharges,
      totalAmount: _totalAmount,
      executedAt: now,
      exchange: _selectedExchange,
      productType: _selectedProductType,
      orderType: 'Market',
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
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to execute trade: ${e.toString()}'),
          ),
        );
      }
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
      limitPrice: _price,
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
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to place limit order: ${e.toString()}'),
          ),
        );
      }
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
            'Buy Stock',
            style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            "Please log in to buy stocks.",
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
          'Buy ${widget.instrument.symbol.replaceAll('-EQ', '')}',
          // --- ⭐️ MODIFIED: Theme text color ---
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
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
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBuyButton(context), // ⭐️ Pass context
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

    bool isLimit = _selectedOrderType == 'Limit';

    return Column(
      children: [
        _buildSegmentedControl(
          context: context, // ⭐️ Pass context
          title: 'Type',
          options: ['Market', 'Limit'],
          selectedValue: _selectedOrderType,
          onChanged: _onOrderTypeChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
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
                  labelStyle: TextStyle(
                    // --- ⭐️ MODIFIED: Theme grey color ---
                    color: textTheme.bodySmall?.color,
                    fontSize: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      // --- ⭐️ MODIFIED: Theme border color ---
                      color: theme.dividerColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      // --- ⭐️ MODIFIED: Theme accent color (Pink) ---
                      color: colorScheme.secondary,
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: isLimit,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // --- ⭐️ MODIFIED: Theme text/grey color ---
                  color: isLimit
                      ? colorScheme.onSurface
                      : textTheme.bodySmall?.color,
                ),
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(
                    // --- ⭐️ MODIFIED: Theme grey color ---
                    color: textTheme.bodySmall?.color,
                    fontSize: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      // --- ⭐️ MODIFIED: Theme border color ---
                      color: theme.dividerColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      // --- ⭐️ MODIFIED: Theme accent color (Pink) ---
                      color: colorScheme.secondary,
                      width: 2.0,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      // --- ⭐️ MODIFIED: Theme border color ---
                      color: theme.dividerColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 12.0),
          child: Row(
            children: [
              Text(
                'Available Funds: ',
                style: TextStyle(
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  color: textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isLoadingFunds)
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    // --- ⭐️ MODIFIED: Theme grey color ---
                    color: textTheme.bodySmall?.color,
                  ),
                )
              else
                Text(
                  _priceFormatter.format(_availableFunds),
                  style: TextStyle(
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSegmentedControl(
          context: context, // ⭐️ Pass context
          title: 'Product',
          options: ['Delivery', 'Intraday'],
          selectedValue: _selectedProductType,
          onChanged: (value) => setState(() => _selectedProductType = value),
        ),
        const SizedBox(height: 16),
        _buildSegmentedControl(
          context: context, // ⭐️ Pass context
          title: 'Exchange',
          options: ['NSE', 'BSE'],
          selectedValue: _selectedExchange,
          onChanged: (value) => setState(() => _selectedExchange = value),
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
                      // --- ⭐️ MODIFIED: Theme accent color (Pink) ---
                      color: isSelected
                          ? (isEnabled
                                ? colorScheme.secondary
                                : theme.disabledColor)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        // --- ⭐️ MODIFIED: Theme text colors ---
                        color: isSelected
                            ? colorScheme.onSecondary
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
            // ⭐️ Pass context
            context,
            'Price',
            _selectedOrderType == 'Market'
                ? 'Market'
                : formatter.format(_price),
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            context,
            'Subtotal',
            formatter.format(_quantity * _price),
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
            formatter.format(_totalCharges),
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

  Widget _buildBottomBuyButton(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // --- ⭐️ MODIFIED: Theme nav bar color ---
      color: theme.bottomNavigationBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ElevatedButton(
        onPressed: (_quantity > 0 && _price > 0 && !_isPlacingOrder)
            ? _handleBuy
            : null,
        style: ElevatedButton.styleFrom(
          // --- ⭐️ MODIFIED: Theme accent color (Pink) ---
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          // --- ⭐️ MODIFIED: Theme disabled color ---
          disabledBackgroundColor: colorScheme.secondary.withOpacity(0.3),
        ),
        child: _isPlacingOrder
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSecondary,
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
                'Buy Charges Breakdown',
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
              _buildChargeRow(context, 'STT (Buy)', _chargesBreakdown['stt']),
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

  void _showInsufficientFundsDialog(
    BuildContext context,
    double available,
    double required,
  ) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final double shortAmount = required - available;
    final String shortAmountStr = _priceFormatter.format(shortAmount);
    final String availableStr = _priceFormatter.format(available);
    final String requiredStr = _priceFormatter.format(required);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // --- ⭐️ MODIFIED: Theme surface color ---
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Insufficient Funds',
                // --- ⭐️ MODIFIED: Theme text color ---
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You do not have enough funds to place this order.',
                style: TextStyle(
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              _buildFundDetailRow(context, 'Required Amount:', requiredStr),
              _buildFundDetailRow(context, 'Available Funds:', availableStr),
              const Divider(height: 24, thickness: 1),
              _buildFundDetailRow(
                context,
                'You are short by:',
                shortAmountStr,
                isShortfall: true,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                // --- ⭐️ MODIFIED: Theme grey color ---
                style: TextStyle(
                  color: textTheme.bodySmall?.color,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // --- ⭐️ MODIFIED: Theme accent color (Pink) ---
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text('Add Funds', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // TODO: Navigate to your Add Funds Page
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFundDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isShortfall = false,
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
              // --- ⭐️ MODIFIED: Theme grey color ---
              color: textTheme.bodySmall?.color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              // --- ⭐️ MODIFIED: Theme text/error color ---
              color: isShortfall ? colorScheme.error : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
