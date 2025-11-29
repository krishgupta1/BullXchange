import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:flutter/services.dart';
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

  // Define the custom Sell Color from your screenshot (Vibrant Blue/Purple)
  final Color _sellColor = const Color(0xFF536DFE);

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
          ? 'Exceeds holdings ($_ownedQuantity)'
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
    HapticFeedback.mediumImpact();
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
      transactionTime: now,
    );

    final holdingUpdate = StockHoldingModel(
      stockName: widget.instrument.name,
      stockSymbol: symbol,
      quantity: -_quantity,
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
          (route) => route.isFirst,
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
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Text(
            "Please log in to sell stocks.",
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
              'Sell Order',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              widget.instrument.symbol.replaceAll('-EQ', ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _sellColor, // Updated color in header
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
            _buildBottomSellButton(context),
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
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _sellColor.withOpacity(0.1), // Updated background
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "SELL",
              style: theme.textTheme.labelMedium?.copyWith(
                color: _sellColor, // Updated text color
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Quantity",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Holding: $_ownedQuantity',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '0',
            errorText: _errorText,
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
          ),
        ),
      ],
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
          _buildSummaryRow(context, 'Price', formatter.format(_ltp)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildSummaryRow(
            context,
            'Subtotal',
            formatter.format(_quantity * _ltp),
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
                'Total Receive',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatter.format(_totalAmount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
                  color: colorScheme.onSurface,
                  size: 18,
                ),
              ),
            ],
          ),
          Text(
            "-${formatter.format(_totalCharges)}",
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

  // ---------------------------------------------------------------------------
  // ----------------- UPDATED SWIPE TO SELL BUTTON ----------------------------
  // ---------------------------------------------------------------------------

  Widget _buildBottomSellButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isEnabled = _quantity > 0 && !_isPlacingOrder && _errorText == null;

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
      child: isEnabled
          ? SwipeToConfirmButton(
              onConfirmed: _handleSell,
              label: "Swipe to Sell",
              // CHANGED: Use the vibrant Blue/Purple from your screenshot
              color: _sellColor,
              icon: Icons.double_arrow_rounded,
            )
          : SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.disabledColor.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "Swipe to Sell",
                        style: TextStyle(
                          // CHANGED: Use onSurface with opacity to ensure visibility in dark mode
                          // 'disabledColor' is often too dark on black backgrounds
                          color: colorScheme.onSurface.withOpacity(0.35),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
    );
  }

  void _showChargeDetailsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = _priceFormatter;

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
                'Sell Charges Breakdown',
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
                'STT (Sell)',
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
                    formatter.format(_chargesBreakdown['total'] ?? 0.0),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
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
    final formatter = _priceFormatter;

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
            formatter.format(value ?? 0.0),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ----------------- CUSTOM SWIPE TO CONFIRM WIDGET --------------------------
// ---------------------------------------------------------------------------

class SwipeToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;
  final Color color;
  final IconData icon;

  const SwipeToConfirmButton({
    super.key,
    required this.onConfirmed,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  State<SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<SwipeToConfirmButton> {
  double _position = 0.0;
  bool _isConfirmed = false;
  final double _height = 56.0;
  final double _padding = 4.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxDrag = maxWidth - _height; // Width minus knob size

        return Container(
          height: _height,
          width: maxWidth,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Text Background
              Center(
                child: Opacity(
                  opacity: (1 - (_position / maxDrag)).clamp(0.0, 1.0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // 2. Active Track Fill
              Container(
                width: _position + _height,
                height: _height,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Or a fill color if desired
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              // 3. Sliding Knob
              Positioned(
                left: _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _position += details.delta.dx;
                      // Clamp position
                      if (_position < 0) _position = 0;
                      if (_position > maxDrag) _position = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isConfirmed) return;
                    // Threshold check (e.g., 70% of width)
                    if (_position > maxDrag * 0.7) {
                      setState(() {
                        _position = maxDrag;
                        _isConfirmed = true;
                      });
                      widget.onConfirmed();
                      // Optional: Reset after delay if validation fails externally
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _isConfirmed = false;
                            _position = 0;
                          });
                        }
                      });
                    } else {
                      // Snap back
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    height: _height - (_padding * 2),
                    width: _height - (_padding * 2),
                    margin: EdgeInsets.only(left: _padding),
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
