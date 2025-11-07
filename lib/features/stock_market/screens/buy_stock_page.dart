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
  // --- UI Constants ---
  static const Color primaryPink = Color(0xFFF61C7A);
  static const Color darkTextColor = Color(0xFF03314B);
  static const Color lightGreyBg = Color(0xFFF5F5F5);
  static const Color lightBorderColor = Color(0xFFE0E0E0);
  static const Color secondaryTextColor = Color(0xFF6A7584);
  // ---

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

  // --- ADDED FOR AVAILABLE FUNDS ---
  double _availableFunds = 0.0;
  bool _isLoadingFunds = true;
  // ---

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

    // --- FETCH FUNDS ---
    _fetchAvailableFunds();
    _calculateTotal(); // Initial calculation
  }

  // --- NEW METHOD ---
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
      // Handle error, maybe show a snackbar
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
      final double tradeValue = _quantity * _price; // Use _price not _ltp

      _chargesBreakdown = _chargeCalculator.calculateBuyCharges(tradeValue);
      _totalCharges = _chargesBreakdown['total'] ?? 0.0;

      _totalAmount = (_quantity > 0) ? (tradeValue + _totalCharges) : 0.0;
    });
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotal);
    _limitPriceController.removeListener(_onPriceChanged);
    _quantityController.dispose();
    _limitPriceController.dispose();
    super.dispose();
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

    // Check funds one more time before placing order
    if (_totalAmount > _availableFunds) {
      if (mounted) {
        _showInsufficientFundsDialog(_availableFunds, _totalAmount);
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
    // --- AUTH CHECK ---
    final auth = FirebaseAuth.instance;
    if (auth.currentUser?.uid == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Buy Stock',
            style: TextStyle(
              color: darkTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: Text("Please log in to buy stocks.")),
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
          'Buy ${widget.instrument.symbol.replaceAll('-EQ', '')}',
          style: const TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      // --- ⭐️ BODY WITH REDUCED PADDING ---
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
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
          ),
        ],
      ),

      // --- END OF SOLUTION ---
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
    bool isLimit = _selectedOrderType == 'Limit';

    return Column(
      children: [
        _buildSegmentedControl(
          title: 'Type',
          options: ['Market', 'Limit'],
          selectedValue: _selectedOrderType,
          onChanged: _onOrderTypeChanged,
          activeColor: primaryPink, // Pass the theme color
        ),
        const SizedBox(height: 16), // --- MODIFIED ---
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
                  labelStyle: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
                  ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: isLimit,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLimit ? darkTextColor : Colors.grey,
                ),
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
                  ),
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
        // --- NEW: AVAILABLE FUNDS ---
        Padding(
          padding: const EdgeInsets.only(
            top: 10.0,
            left: 12.0,
          ), // --- MODIFIED ---
          child: Row(
            children: [
              Text(
                'Available Funds: ',
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isLoadingFunds)
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: secondaryTextColor,
                  ),
                )
              else
                Text(
                  _priceFormatter.format(_availableFunds),
                  style: const TextStyle(
                    color: darkTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        // --- END NEW ---
        const SizedBox(height: 16), // --- MODIFIED ---
        _buildSegmentedControl(
          title: 'Product',
          options: ['Delivery', 'Intraday'],
          selectedValue: _selectedProductType,
          onChanged: (value) => setState(() => _selectedProductType = value),
          activeColor: primaryPink,
        ),
        const SizedBox(height: 16), // --- MODIFIED ---
        _buildSegmentedControl(
          title: 'Exchange',
          options: ['NSE', 'BSE'],
          selectedValue: _selectedExchange,
          onChanged: (value) => setState(() => _selectedExchange = value),
          activeColor: primaryPink,
        ),
      ],
    );
  }

  // --- UPDATED: Replaced with the more complex version from SellStockPage ---
  Widget _buildSegmentedControl({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    bool isEnabled = true,
    Color? activeColor, // Optional active color
  }) {
    final color = activeColor ?? primaryPink; // Use pink as default
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
          _buildSummaryRow(
            'Price',
            _selectedOrderType == 'Market'
                ? 'Market'
                : formatter.format(_price),
          ),
          const Divider(height: 24),
          _buildSummaryRow('Subtotal', formatter.format(_quantity * _price)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Charges',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: secondaryTextColor,
                        size: 18,
                      ),
                      onPressed: () => _showChargeDetailsBottomSheet(context),
                    ),
                  ],
                ),
                Text(
                  formatter.format(_totalCharges),
                  style: const TextStyle(
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

  Widget _buildBottomBuyButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // --- MODIFIED ---
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
              const Text(
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

  void _showInsufficientFundsDialog(double available, double required) {
    final double shortAmount = required - available;

    final String shortAmountStr = _priceFormatter.format(shortAmount);
    final String availableStr = _priceFormatter.format(available);
    final String requiredStr = _priceFormatter.format(required);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Insufficient Funds',
                style: TextStyle(color: darkTextColor),
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
                  color: darkTextColor.withOpacity(0.8),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              _buildFundDetailRow('Required Amount:', requiredStr),
              _buildFundDetailRow('Available Funds:', availableStr),
              const Divider(height: 24, thickness: 1),
              _buildFundDetailRow(
                'You are short by:',
                shortAmountStr,
                isShortfall: true,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink, // Use your theme color
                foregroundColor: Colors.white,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.blue,
                    content: Text('Navigate to Add Funds Page (TODO)'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFundDetailRow(
    String label,
    String value, {
    bool isShortfall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isShortfall ? Colors.red : darkTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
