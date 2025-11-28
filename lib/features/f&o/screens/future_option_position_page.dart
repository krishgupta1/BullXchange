import 'package:bullxchange/features/f&o/widgets/share_pnl_card.dart';
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// --- 1. MAIN F&O POSITIONS PAGE ---
class FnoPositionsPage extends StatefulWidget {
  const FnoPositionsPage({super.key});

  @override
  State<FnoPositionsPage> createState() => _FnoPositionsPageState();
}

class _FnoPositionsPageState extends State<FnoPositionsPage> {
  final UserService _userService = UserService();

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
          final double invested = position.averagePrice * position.quantity;
          final double currentVal = ltp * position.quantity;

          totalOverallPnl += (currentVal - invested);
          totalInvestment += invested;
        }

        double totalPnlPercent = 0.0;
        if (totalInvestment > 0) {
          totalPnlPercent = (totalOverallPnl / totalInvestment) * 100;
        }

        return Scaffold(
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Summary Card (Matched Style) ---
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    endIndent: 16,
                    color: theme.dividerColor.withOpacity(0.15),
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
          // --- ⭐️ ADDED TOTAL P&L BOTTOM BAR ---
          bottomNavigationBar: _FnoBottomPnlBar(
            totalPnl: totalOverallPnl,
            totalPnlPercent: totalPnlPercent,
            totalInvested: totalOverallPnl,
            totalCurrentValue: totalInvestment + totalOverallPnl,
          ),
        );
      },
    );
  }

  // --- SUMMARY CARD (Matched to PositionPage) ---
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
    final profitColor = isDark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF00C853);
    final lossColor = isDark
        ? const Color(0xFFEF5350)
        : const Color(0xFFFF3D00);
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: P&L
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
                        "$sign₹${totalPnl.abs().toStringAsFixed(2)}",
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
                  color: pnlColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$sign${totalPnlPercent.abs().toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          const SizedBox(height: 14),

          // Bottom Row: Invested & Exit Button
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
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${totalInvestment.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onExitAll,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 6),
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
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on_rounded, size: 10, color: Colors.orange),
          const SizedBox(width: 3),
          Text(
            "F&O",
            style: TextStyle(
              fontSize: 9,
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

    // Clean, sharp colors
    final pnlColor = isProfit
        ? const Color(0xFF4CAF50) // Material Green
        : const Color(0xFFF44336); // Material Red

    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Container(
      // Minimal margin, closer to bottom
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Matte Black/Grey
        borderRadius: BorderRadius.circular(12), // Tighter radius
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              // Compact Padding
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- COMPACT HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Label + Value in one line
                      Row(
                        children: [
                          Text(
                            "P&L",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${isProfit ? '+' : ''}${formatter.format(widget.totalPnl)}",
                            style: TextStyle(
                              color: pnlColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),

                      // Right: % and Chevron
                      Row(
                        children: [
                          Text(
                            "${widget.totalPnlPercent.abs().toStringAsFixed(2)}%",
                            style: TextStyle(
                              color: pnlColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // --- HIDDEN DETAILS ---
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    // Thin separator
                    Container(height: 1, color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 10),

                    // Single Row Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniDetail(
                          "Invested",
                          widget.totalInvested,
                          formatter,
                        ),
                        _buildMiniDetail(
                          "Current",
                          widget.totalCurrentValue,
                          formatter,
                        ),
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
        Text(
          "$label: ",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        Text(
          formatter.format(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// --- LIST ITEM WIDGET (Unchanged) ---
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
        final instrument = _provider.getInstrumentBySymbol(
          widget.position.contractSymbol,
        );

        final double currentLtp =
            (instrument?.liveData['ltp'] as num?)?.toDouble() ??
            widget.position.averagePrice;

        final double invested =
            widget.position.averagePrice * widget.position.quantity;
        final double currentVal = currentLtp * widget.position.quantity;
        final double pnl = currentVal - invested;
        final double roi = (invested > 0) ? (pnl / invested) * 100 : 0.0;

        _ltpNotifier.value = currentLtp;
        _plNotifier.value = pnl;
        _roiNotifier.value = roi;
      } catch (e) {
        // Fallback or error handling
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final isCe = widget.position.optionType.toUpperCase() == "CE";
    final typeColor = isCe ? Colors.green : Colors.red;

    return InkWell(
      onTap: _showShareCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            // Badge (CE/PE)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  widget.position.optionType,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.position.contractSymbol,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "F&O",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.position.quantity} Qty",
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Numbers
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _ltpNotifier,
                  builder: (_, ltp, __) => Text(
                    formatter.format(ltp * widget.position.quantity),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<double>(
                  valueListenable: _plNotifier,
                  builder: (_, pnl, __) {
                    final isProfit = pnl >= 0;
                    final pnlColor = isProfit
                        ? (isDark
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFF00C853))
                        : (isDark
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFFF3D00));

                    return ValueListenableBuilder<double>(
                      valueListenable: _roiNotifier,
                      builder: (_, roi, __) => Text(
                        "${isProfit ? '+' : ''}${formatter.format(pnl)} (${roi.toStringAsFixed(2)}%)",
                        style: TextStyle(
                          color: pnlColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- EMPTY STATE ---
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
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
          "No Open F&O Positions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your options trades will appear here.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
