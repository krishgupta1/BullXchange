import 'package:bullxchange/features/stock_market/screens/transaction_success_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final UserService _userService = UserService();
  final ChargeCalculatorService _calculator = ChargeCalculatorService();

  String _productType = 'NRML';
  int _lotSize = 25;
  int _totalQty = 25;
  double _totalAmount = 0.0;
  double _charges = 0.0;
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

  void _calculate() {
    setState(() {
      int lots = int.tryParse(_lotsController.text) ?? 0;
      _totalQty = lots * _lotSize;
      double tradeValue = _totalQty * widget.ltp;

      var breakdown = _calculator.calculateOptionCharges(
        tradeValue,
        false,
      ); // Buy=False
      _charges = breakdown['total'] ?? 0.0;
      _totalAmount = tradeValue - _charges;
    });
  }

  Future<void> _handleSell() async {
    if (_totalQty <= 0 || _isPlacingOrder) return;

    setState(() => _isPlacingOrder = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final contractSymbol =
        "${widget.symbol} ${widget.strikePrice.toInt()} ${widget.optionType}";

    final transaction = TransactionModel(
      userId: uid,
      stockSymbol: contractSymbol,
      companyName: widget.instrument.name,
      transactionType: 'SELL',
      quantity: _totalQty,
      price: widget.ltp,
      charges: _charges,
      totalAmount: _totalAmount,
      exchange: 'NFO',
      productType: _productType,
      orderType: 'Market',
      transactionTime: DateTime.now(),
      lotSize: _lotSize,
      optionType: widget.optionType,
      strikePrice: widget.strikePrice,
      expiryDate: widget.instrument.expiry,
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
      exchange: 'NFO',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sell ${widget.optionType}"),
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "${widget.symbol} ${widget.strikePrice.toInt()} ${widget.optionType}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              _formatter.format(widget.ltp),
              style: const TextStyle(fontSize: 24, color: Colors.red),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _lotsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Lots to Sell",
                border: const OutlineInputBorder(),
                helperText: "1 Lot = $_lotSize | Total: $_totalQty Qty",
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Receivable"),
                Text(
                  _formatter.format(_totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _handleSell,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isPlacingOrder
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SELL", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
