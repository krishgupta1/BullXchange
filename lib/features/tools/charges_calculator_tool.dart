import 'dart:ui';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChargesPage extends StatefulWidget {
  const ChargesPage({super.key});

  @override
  State<ChargesPage> createState() => _ChargesPageState();
}

class _ChargesPageState extends State<ChargesPage> {
  final ChargeCalculatorService _service = ChargeCalculatorService();
  final TextEditingController _controller = TextEditingController();

  TradeType _selectedType = TradeType.buy;
  Map<String, double>? _charges;

  // --- COLORS EXTRACTED FROM UPLOADED HOLDINGS IMAGE ---
  // Buy Button (Right side of image): Vibrant Pink/Red
  final Color _buyColor = const Color(0xFFFF2E63);
  // Sell Button (Left side of image): Electric Indigo/Purple
  final Color _sellColor = const Color(0xFF5345E6);

  Color get _activeColor =>
      _selectedType == TradeType.buy ? _buyColor : _sellColor;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Logic Helpers ---
  void _calculate() {
    final double tradeValue =
        double.tryParse(_controller.text.replaceAll(',', '')) ?? 0.0;
    FocusScope.of(context).unfocus();

    if (tradeValue <= 0) {
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

  String _formatCurrency(double amount) {
    final s = amount.toStringAsFixed(2);
    final parts = s.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₹$integer.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final tileColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'Charges Estimator',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          // Add padding at bottom for the fixed button
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- INPUT SECTION ---
              _buildSectionHeader('Transaction Details', theme.textTheme),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Toggle Switch
                    _buildTradeTypeSelector(isDarkMode),

                    const SizedBox(height: 24),

                    // Amount Input
                    Column(
                      children: [
                        Text(
                          "ENTER TURNOVER",
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            fontFamily: 'EudoxusSans',
                          ),
                          cursorColor: _activeColor,
                          decoration: InputDecoration(
                            hintText: "₹0",
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.2),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.,]'),
                            ),
                            ThousandsFormatter(),
                          ],
                          onChanged: (val) => setState(() {}),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- RESULTS SECTION ---
              if (_charges != null) ...[
                _buildSectionHeader('Cost Breakdown', theme.textTheme),

                Container(
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // List Items
                      _buildResultRow(
                        "Brokerage",
                        _charges!['brokerage']!,
                        icon: Icons.handshake_outlined,
                        color: Colors.blue,
                      ),
                      _buildDivider(theme),
                      _buildResultRow(
                        "STT / CTT",
                        _charges!['stt']!,
                        icon: Icons.receipt_long,
                        color: Colors.orange,
                      ),
                      _buildDivider(theme),
                      _buildResultRow(
                        "Exchange Txn",
                        _charges!['exchangeCharges']!,
                        icon: Icons.account_balance,
                        color: Colors.purple,
                      ),
                      _buildDivider(theme),
                      _buildResultRow(
                        "SEBI Charges",
                        _charges!['sebiCharges']!,
                        icon: Icons.verified_user_outlined,
                        color: Colors.teal,
                      ),
                      _buildDivider(theme),
                      _buildResultRow(
                        "Stamp Duty",
                        _charges!['stampDuty']!,
                        icon: Icons.confirmation_number_outlined,
                        color: Colors.indigo,
                      ),
                      _buildDivider(theme),
                      _buildResultRow(
                        "GST (18%)",
                        _charges!['gst']!,
                        icon: Icons.percent,
                        color: Colors.pinkAccent,
                      ),

                      // Total Section
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black26
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Net Charges",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatCurrency(_charges!['total']!),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _activeColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Disclaimer
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Note: Charges are approximate and may vary slightly based on exchange regulations.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ),
              ] else ...[
                // Empty State
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 48,
                          color: theme.dividerColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Enter amount to estimate costs",
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      // --- FIXED BOTTOM BUTTON ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _controller.text.isEmpty ? null : _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeColor, // Pink for Buy, Blue for Sell
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _activeColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: theme.disabledColor.withOpacity(0.1),
                ),
                child: Text(
                  "CALCULATE ${_selectedType == TradeType.buy ? 'BUY' : 'SELL'} CHARGES",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textTheme.bodySmall?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: theme.dividerColor.withOpacity(0.1),
    );
  }

  Widget _buildResultRow(
    String title,
    double value, {
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeTypeSelector(bool isDarkMode) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton("Buy", TradeType.buy)),
          const SizedBox(width: 4),
          Expanded(child: _buildSegmentButton("Sell", TradeType.sell)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, TradeType type) {
    final isSelected = _selectedType == type;
    // Use the specific colors for the selected text
    final color = type == TradeType.buy ? _buyColor : _sellColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedType = type;
          if (_controller.text.isNotEmpty) _calculate();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? color : Theme.of(context).hintColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// --- Utilities ---

enum TradeType { buy, sell }

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

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final cleaned = newValue.text.replaceAll(',', '');
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
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
