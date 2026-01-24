import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SellOptionPage extends StatefulWidget {
  final Instrument instrument;
  final String symbol;
  final String optionType;
  final double strikePrice;
  final double ltp;

  const SellOptionPage({
    super.key,
    required this.instrument,
    required this.symbol,
    required this.optionType,
    required this.strikePrice,
    required this.ltp,
  });

  @override
  State<SellOptionPage> createState() => _SellOptionPageState();
}

class _SellOptionPageState extends State<SellOptionPage> {
  final _lotsController = TextEditingController(text: "1");
  // 1. Add Controllers
  final _targetController = TextEditingController();
  final _slController = TextEditingController();

  final UserService _userService = UserService();
  final ChargeCalculatorService _calculator = ChargeCalculatorService();

  final String _productType = 'NRML';
  int _lotSize = 25;
  int _totalQty = 25;
  double _totalAmount = 0.0;
  double _charges = 0.0;
  Map<String, double> _chargesBreakdown = {};
  bool _isPlacingOrder = false;

  final _formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _lotSize = int.tryParse(widget.instrument.lotSize) ?? 25;
    _totalQty = _lotSize;
    _lotsController.addListener(_calculate);
    _calculate();
  }

  @override
  void dispose() {
    _lotsController.removeListener(_calculate);
    _lotsController.dispose();
    // 2. Dispose
    _targetController.dispose();
    _slController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      int lots = int.tryParse(_lotsController.text) ?? 0;
      _totalQty = lots * _lotSize;
      double tradeValue = _totalQty * widget.ltp;

      _chargesBreakdown = _calculator.calculateOptionCharges(
        tradeValue,
        false, // Buy = false (Sell)
      );
      _charges = _chargesBreakdown['total'] ?? 0.0;
      _totalAmount = tradeValue - _charges;
    });
  }

  Future<void> _handleSell() async {
    if (_totalQty <= 0 || _isPlacingOrder) return;

    setState(() => _isPlacingOrder = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final contractSymbol =
        "${widget.symbol} ${widget.strikePrice.toInt()} ${widget.optionType}";

    // 3. Parse Inputs
    double? targetPrice = double.tryParse(_targetController.text);
    double? slPrice = double.tryParse(_slController.text);

    final transaction = TransactionModel(
      userId: uid,
      stockSymbol: contractSymbol,
      companyName: widget.instrument.name,
      transactionType: 'SELL',
      quantity: _totalQty,
      price: widget.ltp,
      charges: _charges,
      totalAmount: _totalAmount,
      exchange: 'F&O',
      productType: _productType,
      orderType: 'Market',
      transactionTime: DateTime.now(),
      lotSize: _lotSize,
      optionType: widget.optionType,
      strikePrice: widget.strikePrice,
      expiryDate: widget.instrument.expiry,
      // 4. Add to Transaction
      target: targetPrice,
      stopLoss: slPrice,
    );

    // Negative Qty indicates reducing/closing position
    final optionHolding = OptionHoldingModel(
      symbol: widget.symbol,
      contractSymbol: contractSymbol,
      optionType: widget.optionType,
      strikePrice: widget.strikePrice,
      expiryDate: widget.instrument.expiry,
      quantity: -_totalQty,
      lotSize: _lotSize,
      averagePrice: widget.ltp,
      investedAmount: _totalAmount,
      currentLtp: widget.ltp,
      transactionType: _productType,
      exchange: 'F&O',
      // 5. Add to Holding
      target: targetPrice,
      stopLoss: slPrice,
    );

    try {
      String id = await _userService.executeOptionTrade(
        uid: uid,
        transaction: transaction,
        optionUpdate: optionHolding,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionSuccessPage(
              transaction: transaction,
              transactionId: id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedContract =
        "${widget.symbol} ${widget.strikePrice.toInt()} ${widget.optionType}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Column(
          children: [
            Text(
              'Sell Option',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formattedContract,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
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
                    _buildHeader(context, formattedContract),
                    const SizedBox(height: 24),
                    _buildInputSection(context),
                    const SizedBox(height: 24),
                    // 6. Add UI Section
                    _buildTargetSLSection(context),
                    const SizedBox(height: 24),
                    _buildOrderSummary(context),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  // 7. New UI Widget
  Widget _buildTargetSLSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Stop Loss",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _slController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "Optional",
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                  ),
                ),
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
                "Take Profit",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "Optional",
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ... Existing methods (_buildHeader, _buildInputSection, _buildOrderSummary, etc) ...

  // Copying _buildHeader for completeness
  Widget _buildHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
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
                      color: colorScheme.outline.withValues(alpha: 0.1),
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
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatter.format(widget.ltp),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "SELL",
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lots to Sell (x$_lotSize)",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _lotsController,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "1",
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ), // Use primary for consistent UI, or error color
                      ),
                    ),
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
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Market",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.disabledColor,
                      ),
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

  Widget _buildOrderSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
                  color: theme.disabledColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            context,
            "Quantity",
            "$_totalQty ($_lotSize x ${_lotsController.text})",
          ),
          _buildSummaryRow(context, "Price", _formatter.format(widget.ltp)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildSummaryRow(
            context,
            "Subtotal",
            _formatter.format(_totalQty * widget.ltp),
          ),
          _buildChargesRow(context),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Receivable",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatter.format(_totalAmount),
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

  Widget _buildChargesRow(BuildContext context) {
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
                "Charges & Taxes",
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
            "-${_formatter.format(_charges)}",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
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

  Widget _buildBottomButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isEnabled = _totalQty > 0 && !_isPlacingOrder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? _handleSell : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary, // Often Red/Error for sell
            foregroundColor: Colors.white,
            elevation: isEnabled ? 4 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text(
                  "Swipe to Sell",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  void _showChargeDetailsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sell Charges Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ..._chargesBreakdown.entries
                .where((e) => e.key != 'total')
                .map(
                  (e) => _buildSummaryRow(
                    context,
                    e.key.toUpperCase(),
                    _formatter.format(e.value),
                  ),
                ),
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
                  _formatter.format(_charges),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
