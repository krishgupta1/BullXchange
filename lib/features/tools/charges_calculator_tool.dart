import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChargesApp extends StatelessWidget {
  const ChargesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bullxchange Charges',
      debugShowCheckedModeBanner: false,
      // Support both light and dark themes and respect system setting
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'EudoxusSans',
        scaffoldBackgroundColor: const Color(0xFFF2F4F7), // Premium Light Grey
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2962FF),
          surface: Colors.white,
          background: const Color(0xFFF2F4F7),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF2F4F7),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          // Status bar icons dark for light theme
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Android
            statusBarBrightness: Brightness.light, // iOS
          ),
          titleTextStyle: const TextStyle(
            color: Color(0xFF1A1F36),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.5),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF071022),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D09C),
          background: const Color(0xFF071022),
          surface: const Color(0xFF0B1622),
          brightness: Brightness.dark,
        ),
        // Ensure dark theme uses the app font
        textTheme: ThemeData(fontFamily: 'EudoxusSans').textTheme,
        primaryTextTheme: ThemeData(fontFamily: 'EudoxusSans').primaryTextTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF071022),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B1622),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Color(0xFF00D09C), width: 1.5),
          ),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}

// --- Custom Components ---

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        color: Theme.of(context).iconTheme.color,
        padding: EdgeInsets.zero,
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

/// A dashed line separator for the receipt look
class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const DashedDivider({super.key, this.height = 1, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const double dashWidth = 6.0; // Typo fixed here
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

enum TradeType { buy, sell }

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final ChargeCalculatorService _service = ChargeCalculatorService();
  final TextEditingController _controller = TextEditingController();

  TradeType _selectedType = TradeType.buy;
  Map<String, double>? _charges;

  // Bullxchange Brand Colors
  final Color _bullColor = const Color(0xFF00D09C); // Modern Mint Green
  final Color _bearColor = const Color(0xFFFF5252); // Soft Red
  // Use theme-aware text color
  Color get _textColor => Theme.of(context).colorScheme.onSurface;

  Color get _activeColor =>
      _selectedType == TradeType.buy ? _bullColor : _bearColor;

  String _formatCurrency(double amount) {
    final s = amount.toStringAsFixed(2);
    final parts = s.split('.');
    final integer = parts[0];
    final decimals = parts.length > 1 ? '.${parts[1]}' : '';
    final formattedInteger = integer.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₹$formattedInteger$decimals';
  }

  static TextInputFormatter thousandsFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      if (text.isEmpty) return newValue;
      final cleaned = text.replaceAll(',', '');
      if (RegExp(r'\.').allMatches(cleaned).length > 1) return oldValue;
      final parts = cleaned.split('.');
      String intPart = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
      if (intPart.isEmpty) intPart = '0';
      final formattedInt = intPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      final newText = parts.length > 1
          ? '$formattedInt.${parts[1]}'
          : formattedInt;
      int selectionIndex =
          newText.length - (cleaned.length - newValue.selection.end);
      if (selectionIndex < 0) selectionIndex = 0;
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    });
  }

  void _calculate() {
    final double tradeValue =
        double.tryParse(_controller.text.replaceAll(',', '')) ?? 0.0;
    FocusScope.of(context).unfocus();
    if (tradeValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid turnover'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _charges = null);
      return;
    }
    setState(() {
      if (_selectedType == TradeType.buy) {
        _charges = _service.calculateBuyCharges(tradeValue);
      } else {
        _charges = _service.calculateSellCharges(tradeValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tap outside to dismiss keyboard
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const CustomBackButton(),
                    Expanded(
                      child: Text(
                        'Charges Estimator',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 56), // Balance back button
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Custom Toggle Switch
                      _buildTradeTypeSelector(),

                      const SizedBox(height: 32),

                      // Hero Input Section
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "ENTER TURNOVER",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            IntrinsicWidth(
                              child: TextField(
                                controller: _controller,
                                textAlign: TextAlign.center,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                                cursorColor: _activeColor,
                                decoration: InputDecoration(
                                  hintText: "₹0",
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.35),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9\.,]'),
                                  ),
                                  thousandsFormatter(),
                                ],
                                onChanged: (val) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Calculate Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _controller.text.isEmpty
                              ? null
                              : _calculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _activeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: _activeColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Calculate",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Results Section
                      if (_charges != null) _buildResultsReceipt(),

                      // Empty State / Placeholder
                      if (_charges == null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Icon(
                              Icons.bar_chart_rounded,
                              size: 60,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.28),
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeTypeSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedType = TradeType.buy;
                  if (_controller.text.isNotEmpty) _calculate();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedType == TradeType.buy
                      ? _bullColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType == TradeType.buy
                        ? _bullColor
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "BUY",
                  style: TextStyle(
                    color: _selectedType == TradeType.buy
                        ? _bullColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedType = TradeType.sell;
                  if (_controller.text.isNotEmpty) _calculate();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedType == TradeType.sell
                      ? _bearColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType == TradeType.sell
                        ? _bearColor
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "SELL",
                  style: TextStyle(
                    color: _selectedType == TradeType.sell
                        ? _bearColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsReceipt() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Total
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Charges",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_charges!['total']!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Breakdown List
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildReceiptRow("Brokerage", _charges!['brokerage']!),
                _buildReceiptRow("STT / CTT", _charges!['stt']!),
                _buildReceiptRow(
                  "Exchange Txn Charge",
                  _charges!['exchangeCharges']!,
                ),
                _buildReceiptRow("SEBI Charges", _charges!['sebiCharges']!),
                _buildReceiptRow("Stamp Duty", _charges!['stampDuty']!),
                const SizedBox(height: 16),
                DashedDivider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ), // Dashed Line
                const SizedBox(height: 16),
                _buildReceiptRow("GST (18%)", _charges!['gst']!, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// --- START LOGIC (UNMODIFIED) ---
class ChargeCalculatorService {
  Map<String, double> calculateBuyCharges(double tradeValue) {
    if (tradeValue <= 0) return _emptyCharges();

    const brokerage = 0.0;
    final stt = 0.001 * tradeValue;
    final exchangeCharges = 0.0000345 * tradeValue;
    final sebiCharges = 0.00001 * tradeValue;
    final stampDuty = 0.00015 * tradeValue;
    final gst = 0.18 * (brokerage + exchangeCharges);

    final totalCharges =
        brokerage + stt + exchangeCharges + sebiCharges + stampDuty + gst;

    return {
      'brokerage': brokerage,
      'stt': stt,
      'exchangeCharges': exchangeCharges,
      'sebiCharges': sebiCharges,
      'stampDuty': stampDuty,
      'gst': gst,
      'total': totalCharges,
    };
  }

  Map<String, double> calculateSellCharges(double tradeValue) {
    if (tradeValue <= 0) return _emptyCharges();

    const brokerage = 0.0;
    final stt = 0.001 * tradeValue;
    final exchangeCharges = 0.0000345 * tradeValue;
    final sebiCharges = 0.00001 * tradeValue;
    const stampDuty = 0.0;
    final gst = 0.18 * (brokerage + exchangeCharges);

    final totalCharges =
        brokerage + stt + exchangeCharges + sebiCharges + stampDuty + gst;

    return {
      'brokerage': brokerage,
      'stt': stt,
      'exchangeCharges': exchangeCharges,
      'sebiCharges': sebiCharges,
      'stampDuty': stampDuty,
      'gst': gst,
      'total': totalCharges,
    };
  }

  Map<String, double> _emptyCharges() {
    return {
      'brokerage': 0.0,
      'stt': 0.0,
      'exchangeCharges': 0.0,
      'sebiCharges': 0.0,
      'stampDuty': 0.0,
      'gst': 0.0,
      'total': 0.0,
    };
  }
}

// --- END LOGIC ---
