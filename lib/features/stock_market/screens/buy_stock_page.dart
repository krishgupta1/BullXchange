import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

class BuyStockPage extends StatefulWidget {
  final Instrument instrument;
  const BuyStockPage({super.key, required this.instrument});

  @override
  State<BuyStockPage> createState() => _BuyStockPageState();
}

class _BuyStockPageState extends State<BuyStockPage> {
  final _quantityController = TextEditingController();
  final _limitPriceController = TextEditingController();

  String _selectedProductType = 'Delivery';
  final String _selectedExchange = 'NSE'; // Default to NSE, UI toggle removed
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
      debugPrint("Error fetching funds: $e");
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
        _price = _ltp;
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
    HapticFeedback.mediumImpact();
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
      companyName: widget.instrument.name,
      transactionType: 'BUY',
      quantity: _quantity,
      price: _price,
      charges: _totalCharges,
      totalAmount: _totalAmount,
      exchange: _selectedExchange,
      productType: _selectedProductType,
      orderType: 'Market',
      stockSymbol: symbol,
      transactionTime: now,
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
      throw e;
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

    await _userService.placeLimitOrder(newOrder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Limit order for $symbol placed successfully.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = FirebaseAuth.instance;
    if (auth.currentUser?.uid == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: const CustomBackButton(),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            "Please log in to buy stocks.",
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Column(
          children: [
            Text(
              'Buy Order',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              widget.instrument.symbol.replaceAll('-EQ', ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStockHeader(context, _priceFormatter),
                    const SizedBox(height: 24),
                    _buildInputSection(context),
                    const SizedBox(height: 24),
                    _buildOrderSummary(context, _priceFormatter),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomBuyButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStockHeader(BuildContext context, NumberFormat formatter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: SmartLogo(instrument: widget.instrument, radius: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.instrument.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(_ltp),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Available",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(height: 2),
              _isLoadingFunds
                  ? SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.secondary,
                      ),
                    )
                  : Text(
                      _priceFormatter.format(_availableFunds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isLimit = _selectedOrderType == 'Limit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSegmentedControl(
                context: context,
                options: ['Market', 'Limit'],
                selectedValue: _selectedOrderType,
                onChanged: _onOrderTypeChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSegmentedControl(
                context: context,
                options: ['Delivery', 'Intraday'],
                selectedValue: _selectedProductType,
                onChanged: (value) =>
                    setState(() => _selectedProductType = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quantity",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _inputDecoration(theme, hint: '0'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Price",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _limitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: isLimit,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLimit
                          ? colorScheme.onSurface
                          : theme.disabledColor,
                    ),
                    decoration: _inputDecoration(
                      theme,
                      hint: '0.00',
                      fillColor: isLimit
                          ? theme.cardColor
                          : theme.dividerColor.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String hint,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor ?? theme.cardColor,
      contentPadding: const EdgeInsets.all(16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildSegmentedControl({
    required BuildContext context,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: options.map((option) {
          bool isSelected = selectedValue == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(option);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onSecondary
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, NumberFormat formatter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: theme.disabledColor,
              ),
              const SizedBox(width: 8),
              Text(
                "Order Estimate",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.disabledColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(context, 'Quantity', _quantity.toString()),
          _buildSummaryRow(
            context,
            'Price',
            _selectedOrderType == 'Market'
                ? 'Market'
                : formatter.format(_price),
          ),
          _buildChargesRow(context, formatter),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatter.format(_totalAmount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChargesRow(BuildContext context, NumberFormat formatter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Charges & Taxes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showChargeDetailsBottomSheet(context),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
            ],
          ),
          Text(
            formatter.format(_totalCharges),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBuyButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isEnabled = _quantity > 0 && _price > 0 && !_isPlacingOrder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? _handleBuy : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: Colors.white,
            elevation: isEnabled ? 4 : 0,
            shadowColor: colorScheme.secondary.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: theme.disabledColor.withOpacity(0.1),
            disabledForegroundColor: theme.disabledColor,
          ),
          child: _isPlacingOrder
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  "Swipe to Buy",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  void _showChargeDetailsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Charges Breakdown',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildChargeDetailRow(
                context,
                'Brokerage',
                _chargesBreakdown['brokerage'],
              ),
              _buildChargeDetailRow(
                context,
                'STT (Buy)',
                _chargesBreakdown['stt'],
              ),
              _buildChargeDetailRow(
                context,
                'Exchange Charges',
                _chargesBreakdown['exchangeCharges'],
              ),
              _buildChargeDetailRow(
                context,
                'SEBI Charges',
                _chargesBreakdown['sebiCharges'],
              ),
              _buildChargeDetailRow(
                context,
                'Stamp Duty',
                _chargesBreakdown['stampDuty'],
              ),
              _buildChargeDetailRow(context, 'GST', _chargesBreakdown['gst']),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Charges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _priceFormatter.format(_chargesBreakdown['total'] ?? 0.0),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChargeDetailRow(
    BuildContext context,
    String label,
    double? value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          Text(
            _priceFormatter.format(value ?? 0.0),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double shortAmount = required - available;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Insufficient Funds',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You do not have enough balance to complete this order.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDialogRow(context, 'Required', required),
                    const SizedBox(height: 8),
                    _buildDialogRow(context, 'Available', available),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildDialogRow(
                      context,
                      'Shortfall',
                      shortAmount,
                      isError: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.disabledColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Add Funds'),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to Add Funds if needed
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(
    BuildContext context,
    String label,
    double value, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          _priceFormatter.format(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isError ? colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}
