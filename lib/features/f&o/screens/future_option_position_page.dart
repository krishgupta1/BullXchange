import 'package:bullxchange/features/f&o/widgets/share_pnl_card.dart';
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/utils/option_calculator.dart';
import 'package:bullxchange/services/expiry_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/utils/responsive_helper.dart';

// --- 1. MAIN F&O POSITIONS PAGE ---
class FnoPositionsPage extends StatefulWidget {
  const FnoPositionsPage({super.key});

  @override
  State<FnoPositionsPage> createState() => _FnoPositionsPageState();
}

class _FnoPositionsPageState extends State<FnoPositionsPage> {
  Future<void> _handleExitAllPositions(
    BuildContext context,
    List<OptionHoldingModel> positions,
    InstrumentProvider provider,
  ) async {
    // Placeholder for F&O Exit All Logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Exit All functionality to be implemented for F&O"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive helper
    ResponsiveHelper.init(context, BoxConstraints.tightFor(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
    ));
    
    final auth = FirebaseAuth.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (auth.currentUser?.uid == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: colorScheme.secondary),
            const SizedBox(height: 16),
            const Text("Please log in to see F&O positions."),
          ],
        ),
      );
    }

    return Consumer2<UserProfileDataModel?, InstrumentProvider>(
      builder: (context, userProfile, instrumentProvider, child) {
        final List<OptionHoldingModel> fnoPositions =
            userProfile?.optionHoldings ?? [];

        if (fnoPositions.isEmpty) {
          return const Center(child: _EmptyState());
        }

        // --- Calculate Summary Data (Real-time) ---
        double totalOverallPnl = 0;
        double totalInvestment = 0;

        for (var position in fnoPositions) {
          final instrument = instrumentProvider.getInstrumentBySymbol(
            position.contractSymbol,
          );
          final double ltp =
              (instrument?.liveData['ltp'] as num?)?.toDouble() ??
              position.averagePrice;
          
          final double invested = position.averagePrice * position.quantity.abs();
          final double currentVal = ltp * position.quantity.abs();
          
          double positionPnl;
          if (position.quantity < 0) {
            positionPnl = (position.averagePrice - ltp) * position.quantity.abs();
          } else {
            positionPnl = currentVal - invested;
          }

          totalOverallPnl += positionPnl;
          totalInvestment += invested;
        }

        double totalPnlPercent = 0.0;
        if (totalInvestment > 0) {
          totalPnlPercent = (totalOverallPnl / totalInvestment) * 100;
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          bottomNavigationBar: _FnoBottomPnlBar(
            totalPnl: totalOverallPnl,
            totalPnlPercent: totalPnlPercent,
            totalInvested: totalInvestment,
            totalCurrentValue: totalInvestment + totalOverallPnl,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await ExpiryService.checkAndCleanExpiredPositions();
              if (mounted) {
                setState(() {});
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 120), // Extra space for bottom bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Summary Card ---
                  _buildSummaryCard(
                    context,
                    totalOverallPnl,
                    totalInvestment,
                    onExitAll: () => _handleExitAllPositions(
                      context,
                      fnoPositions,
                      instrumentProvider,
                    ),
                  ),

                  // --- Section Header ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Open Positions (${fnoPositions.length})",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        _buildNfoBadge(context),
                      ],
                    ),
                  ),

                  // --- Position List ---
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: fnoPositions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 72,
                      endIndent: ResponsiveHelper.horizontalPadding,
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      return FnoPositionItem(
                        key: ValueKey(fnoPositions[index].contractSymbol),
                        position: fnoPositions[index],
                      );
                    },
                  ),
              ],
            ),
          ),
        ));
      },
    );
  }

  // --- SUMMARY CARD ---
  Widget _buildSummaryCard(
    BuildContext context,
    double totalPnl,
    double totalInvestment, {
    required VoidCallback onExitAll,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final sign = totalPnl >= 0 ? "+" : "-";
    final profitColor = isDark ? const Color(0xFF66BB6A) : const Color(0xFF00C853);
    final lossColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFFF3D00);
    final pnlColor = totalPnl >= 0 ? profitColor : lossColor;

    double totalPnlPercent = 0.0;
    if (totalInvestment > 0) {
      totalPnlPercent = (totalPnl / totalInvestment) * 100;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.1 : 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total P&L (F&O)",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        sign,
                        style: TextStyle(
                          color: pnlColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "₹${totalPnl.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          color: pnlColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: pnlColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$sign${totalPnlPercent.abs().toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Invested",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${totalInvestment.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onExitAll,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.close_rounded, size: 16, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        "Exit All",
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNfoBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on_rounded, size: 10, color: Colors.orange),
          const SizedBox(width: 3),
          Text(
            "F&O",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FnoBottomPnlBar extends StatefulWidget {
  final double totalPnl;
  final double totalPnlPercent;
  final double totalInvested;
  final double totalCurrentValue;

  const _FnoBottomPnlBar({
    required this.totalPnl,
    required this.totalPnlPercent,
    required this.totalInvested,
    required this.totalCurrentValue,
  });

  @override
  State<_FnoBottomPnlBar> createState() => _FnoBottomPnlBarState();
}

class _FnoBottomPnlBarState extends State<_FnoBottomPnlBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.totalPnl >= 0;
    final pnlColor = isProfit ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text("P&L", style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Text(
                            "${isProfit ? '+' : ''}${formatter.format(widget.totalPnl)}",
                            style: TextStyle(color: pnlColor, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "${widget.totalPnlPercent.abs().toStringAsFixed(2)}%",
                            style: TextStyle(color: pnlColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniDetail("Invested", widget.totalInvested, formatter),
                        _buildMiniDetail("Current", widget.totalCurrentValue, formatter),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDetail(String label, double value, NumberFormat formatter) {
    return Row(
      children: [
        Text("$label: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(formatter.format(value), style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class FnoPositionItem extends StatefulWidget {
  final OptionHoldingModel position;
  const FnoPositionItem({super.key, required this.position});

  @override
  State<FnoPositionItem> createState() => _FnoPositionItemState();
}

class _FnoPositionItemState extends State<FnoPositionItem> {
  final ValueNotifier<double> _ltpNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _plNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _roiNotifier = ValueNotifier(0.0);

  late final InstrumentProvider _provider;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<InstrumentProvider>(context, listen: false);

    _listener = () {
      if (!mounted) return;
      try {
        final instrument = _provider.getInstrumentBySymbol(widget.position.contractSymbol);
        final double currentLtp = (instrument?.liveData['ltp'] as num?)?.toDouble() ?? widget.position.averagePrice;
        final double invested = widget.position.averagePrice * widget.position.quantity.abs();
        final double currentVal = currentLtp * widget.position.quantity.abs();
        
        double pnl;
        if (widget.position.quantity < 0) {
          pnl = (widget.position.averagePrice - currentLtp) * widget.position.quantity.abs();
        } else {
          pnl = currentVal - invested;
        }
        
        final double roi = (invested > 0) ? (pnl / invested) * 100 : 0.0;
        _ltpNotifier.value = currentLtp;
        _plNotifier.value = pnl;
        _roiNotifier.value = roi;
      } catch (_) {}
    };

    _provider.addListener(_listener);
    _listener();
  }

  @override
  void dispose() {
    _provider.removeListener(_listener);
    _ltpNotifier.dispose();
    _plNotifier.dispose();
    _roiNotifier.dispose();
    super.dispose();
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FnoPositionDetailsSheet(
          position: widget.position,
          ltpNotifier: _ltpNotifier,
          plNotifier: _plNotifier,
          roiNotifier: _roiNotifier,
        );
      },
    );
  }

  void _showShareCard() {
    showDialog(
      context: context,
      builder: (context) => SharePnlCard(
        symbol: widget.position.contractSymbol,
        pnl: _plNotifier.value,
        roi: _roiNotifier.value,
        entryPrice: widget.position.averagePrice,
        lastPrice: _ltpNotifier.value,
        isIntraday: false,
      ),
    );
  }

  Instrument? _getBaseInstrument() {
    final symbol = widget.position.contractSymbol.toUpperCase();
    if (symbol.contains('NIFTY')) {
      if (symbol.contains('BANK')) return _provider.bankNifty;
      if (symbol.contains('FIN')) return _provider.finNifty;
      if (symbol.contains('MIDCAP')) return _provider.midcapNifty;
      return _provider.nifty50;
    }
    if (symbol.contains('SENSEX')) return _provider.sensex;
    if (symbol.contains('BANKEX')) return _provider.bankex;
    
    // Fallback: try to find a matching stock by prefix
    final baseSymbol = symbol.split('-').first;
    return _provider.getInstrumentBySymbol(baseSymbol);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isCe = widget.position.optionType.toUpperCase() == "CE";
    final typeColor = isCe ? Colors.green : Colors.red;
    final isShort = widget.position.quantity < 0;
    final baseInstrument = _getBaseInstrument();

    return InkWell(
      onTap: () => _showDetailsSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            // Logo Section
            if (baseInstrument != null)
              SmartLogo(instrument: baseInstrument, radius: 20)
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.position.optionType,
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.position.contractSymbol,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${widget.position.optionType} ${isShort ? 'SHORT' : 'LONG'}",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTimeDecayInfo(context),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${widget.position.quantity.abs()} Qty",
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // P&L
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _ltpNotifier,
                  builder: (context, ltpValue, child) => Text(
                    formatter.format(ltpValue * widget.position.quantity.abs()),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<double>(
                  valueListenable: _plNotifier,
                  builder: (context, pnlValue, child) => ValueListenableBuilder<double>(
                    valueListenable: _roiNotifier,
                    builder: (context, roiValue, child) {
                      final isPos = pnlValue >= 0;
                      final sign = isPos ? "+" : "-";
                      final pnlColor = isPos 
                          ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF00C853))
                          : (isDark ? const Color(0xFFEF5350) : const Color(0xFFFF3D00));
                      return Text(
                        "$sign₹${pnlValue.abs().toStringAsFixed(2)} (${roiValue.abs().toStringAsFixed(2)}%)",
                        style: TextStyle(color: pnlColor, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDecayInfo(BuildContext context) {
    final expiryInfo = OptionCalculator.getExpiryInfo(widget.position.expiryDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color urgencyColor;
    switch (expiryInfo.urgency) {
      case ExpiryUrgency.expired:
        urgencyColor = Colors.grey;
        break;
      case ExpiryUrgency.today:
      case ExpiryUrgency.urgent:
        urgencyColor = Colors.red;
        break;
      case ExpiryUrgency.warning:
        urgencyColor = Colors.orange;
        break;
      case ExpiryUrgency.normal:
        urgencyColor = Colors.blue;
        break;
      case ExpiryUrgency.safe:
        urgencyColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 10, color: urgencyColor),
          const SizedBox(width: 3),
          Text(
            expiryInfo.statusText.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? urgencyColor.withValues(alpha: 0.8) : urgencyColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. BOTTOM SHEET DETAILS ---
class FnoPositionDetailsSheet extends StatelessWidget {
  final OptionHoldingModel position;
  final ValueNotifier<double> ltpNotifier;
  final ValueNotifier<double> plNotifier;
  final ValueNotifier<double> roiNotifier;

  const FnoPositionDetailsSheet({
    super.key,
    required this.position,
    required this.ltpNotifier,
    required this.plNotifier,
    required this.roiNotifier,
  });

  Widget _buildDetailRow(BuildContext context, String title, Widget valueWidget) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  void _showShareCard(BuildContext context) {
      showDialog(
      context: context,
      builder: (context) => SharePnlCard(
        symbol: position.contractSymbol,
        pnl: plNotifier.value,
        roi: roiNotifier.value,
        entryPrice: position.averagePrice,
        lastPrice: ltpNotifier.value,
        isIntraday: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    
    final investedAmount = position.averagePrice * position.quantity.abs();
    final isShort = position.quantity < 0;
    final typeColor = position.optionType.toUpperCase() == "CE" ? Colors.green : Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.contractSymbol,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${position.optionType} ${isShort ? 'SHORT' : 'LONG'}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildExpiryBadge(context, position.expiryDate),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showShareCard(context),
                    icon: const Icon(Icons.share_rounded, size: 20, color: Colors.blue),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.05)),
              const SizedBox(height: 8),

              _buildDetailRow(
                context,
                "Quantity",
                Text(
                  "${position.quantity.abs()} Qty",
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildDetailRow(
                context,
                "Average Price",
                Text(
                  formatter.format(position.averagePrice),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildDetailRow(
                context,
                "LTP",
                ValueListenableBuilder<double>(
                  valueListenable: ltpNotifier,
                  builder: (context, ltpValue, child) => Text(
                    formatter.format(ltpValue),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _buildDetailRow(
                context,
                "P&L",
                ValueListenableBuilder<double>(
                  valueListenable: plNotifier,
                  builder: (context, plValue, child) => ValueListenableBuilder<double>(
                    valueListenable: roiNotifier,
                    builder: (context, roiValue, child) {
                      final isPos = plValue >= 0;
                      final sign = isPos ? "+" : "-";
                      final pnlColor = isPos 
                          ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF00C853))
                          : (isDark ? const Color(0xFFEF5350) : const Color(0xFFFF3D00));
                      return Text(
                        "$sign${formatter.format(plValue)} (${roiValue.abs().toStringAsFixed(2)}%)",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: pnlColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF536DFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'EXIT POSITION',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryBadge(BuildContext context, String expiryDate) {
    final info = OptionCalculator.getExpiryInfo(expiryDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        info.statusText.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.blue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.layers_clear_outlined,
            size: 48,
            color: theme.disabledColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "No F&O Positions",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your options and futures trades will appear here.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
