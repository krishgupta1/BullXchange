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
    ResponsiveHelper.init(
      context,
      BoxConstraints.tightFor(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
      ),
    );

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

          // Handle both long and short positions
          final double invested =
              position.averagePrice * position.quantity.abs();
          final double currentVal = ltp * position.quantity.abs();

          // P&L calculation: For short positions, profit = (sell price - current price)
          double positionPnl;
          if (position.quantity < 0) {
            // Short position: Profit when price goes down
            positionPnl =
                (position.averagePrice - ltp) * position.quantity.abs();
          } else {
            // Long position: Profit when price goes up
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
          bottomNavigationBar: _FnoBottomPnlBar(
            totalPnl: totalOverallPnl,
            totalPnlPercent: totalPnlPercent,
            totalInvested: totalInvestment,
            totalCurrentValue: totalInvestment + totalOverallPnl,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Check expired positions and refresh data
              await ExpiryService.checkAndCleanExpiredPositions();
              // Trigger a rebuild by updating the provider
              if (mounted) {
                setState(() {});
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: ResponsiveHelper.bottomNavHeight,
              ),
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
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.horizontalPadding,
                      ResponsiveHelper.itemSpacing,
                      ResponsiveHelper.horizontalPadding,
                      ResponsiveHelper.smallSpacing,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Open Positions (${fnoPositions.length})",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            fontSize: ResponsiveHelper.h3FontSize,
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
                      indent:
                          ResponsiveHelper.avatarSize +
                          ResponsiveHelper.smallSpacing,
                      endIndent: ResponsiveHelper.horizontalPadding,
                      color: theme.dividerColor.withValues(alpha: 0.15),
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
      margin: EdgeInsets.all(ResponsiveHelper.horizontalPadding),
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: ResponsiveHelper.cardBorderRadius * 0.75,
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
                      fontSize: ResponsiveHelper.captionFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.tinySpacing * 1.5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "$sign₹${totalPnl.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          color: pnlColor,
                          fontSize: ResponsiveHelper.h3FontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.tinySpacing * 2,
                  vertical: ResponsiveHelper.tinySpacing * 1.5,
                ),
                decoration: BoxDecoration(
                  color: pnlColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.cardBorderRadius * 0.4,
                  ),
                ),
                child: Text(
                  "$sign${totalPnlPercent.abs().toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: ResponsiveHelper.captionFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.itemSpacing),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
          SizedBox(height: ResponsiveHelper.itemSpacing),

          // Bottom Row: Invested & Exit All Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Invested",
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: ResponsiveHelper.captionFontSize,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.tinySpacing),
                    Text(
                      "₹${totalInvestment.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: ResponsiveHelper.h3FontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.tinySpacing),
              // Exit All Button Only
              InkWell(
                onTap: onExitAll,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.cardBorderRadius * 0.6,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.horizontalPadding,
                    vertical: ResponsiveHelper.smallSpacing * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.cardBorderRadius * 0.6,
                    ),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: ResponsiveHelper.iconSize * 0.7,
                        color: colorScheme.error,
                      ),
                      SizedBox(width: ResponsiveHelper.tinySpacing * 1.5),
                      Text(
                        "Exit All",
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.captionFontSize,
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.tinySpacing * 1.5,
        vertical: ResponsiveHelper.tinySpacing * 0.75,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.cardBorderRadius * 0.2,
        ),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flash_on_rounded,
            size: ResponsiveHelper.iconSize * 0.4,
            color: Colors.orange,
          ),
          SizedBox(width: ResponsiveHelper.tinySpacing * 0.75),
          Text(
            "F&O",
            style: TextStyle(
              fontSize: ResponsiveHelper.tinyFontSize,
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
      margin: EdgeInsets.fromLTRB(
        ResponsiveHelper.horizontalPadding * 0.75,
        0,
        ResponsiveHelper.horizontalPadding * 0.75,
        ResponsiveHelper.horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Matte Black/Grey
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.cardBorderRadius,
        ), // Tighter radius
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: ResponsiveHelper.cardBorderRadius * 0.5,
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
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding,
                vertical: ResponsiveHelper.itemSpacing,
              ),
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
                              fontSize: ResponsiveHelper.captionFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.tinySpacing * 2),
                          Text(
                            "${isProfit ? '+' : ''}${formatter.format(widget.totalPnl)}",
                            style: TextStyle(
                              color: pnlColor,
                              fontSize: ResponsiveHelper.captionFontSize,
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
                              fontSize: ResponsiveHelper.captionFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.tinySpacing * 2),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: ResponsiveHelper.iconSize * 0.75,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // --- HIDDEN DETAILS ---
                  if (_isExpanded) ...[
                    SizedBox(height: ResponsiveHelper.itemSpacing),
                    // Thin separator
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    SizedBox(height: ResponsiveHelper.smallSpacing),

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
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: ResponsiveHelper.captionFontSize,
          ),
        ),
        Text(
          formatter.format(value),
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveHelper.captionFontSize,
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

        // Handle both long and short positions for individual items
        final double invested =
            widget.position.averagePrice * widget.position.quantity.abs();
        final double currentVal = currentLtp * widget.position.quantity.abs();

        double pnl;
        if (widget.position.quantity < 0) {
          // Short position: Profit when price goes down
          pnl =
              (widget.position.averagePrice - currentLtp) *
              widget.position.quantity.abs();
        } else {
          // Long position: Profit when price goes up
          pnl = currentVal - invested;
        }

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
    final isShort = widget.position.quantity < 0;

    return InkWell(
      onTap: _showShareCard,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.horizontalPadding,
          vertical: ResponsiveHelper.itemSpacing * 1.2,
        ),
        child: Row(
          children: [
            // Badge (CE/PE)
            Container(
              width: ResponsiveHelper.avatarSize * 0.9,
              height: ResponsiveHelper.avatarSize * 0.9,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.cardBorderRadius * 0.6,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.position.optionType,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: isShort
                            ? ResponsiveHelper.tinyFontSize
                            : ResponsiveHelper.smallFontSize,
                      ),
                    ),
                    if (isShort)
                      Text(
                        "SHORT",
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.tinyFontSize * 0.6,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.smallSpacing),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.position.contractSymbol,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.captionFontSize,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.tinySpacing * 1.5),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.tinySpacing,
                          vertical: ResponsiveHelper.tinySpacing * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.cardBorderRadius * 0.2,
                          ),
                        ),
                        child: Text(
                          "F&O",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.tinyFontSize,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.tinySpacing * 1.5),
                      Expanded(
                        child: Text(
                          "${widget.position.quantity.abs()} Qty",
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: ResponsiveHelper.captionFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.tinySpacing * 1.5),
                      // Add time decay info
                      _buildTimeDecayInfo(context),
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
                  builder: (context, ltpValue, child) => Text(
                    formatter.format(ltpValue * widget.position.quantity.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.captionFontSize,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.tinySpacing),
                ValueListenableBuilder<double>(
                  valueListenable: _plNotifier,
                  builder: (context, pnlValue, child) {
                    final isProfit = pnlValue >= 0;
                    final pnlColor = isProfit
                        ? (isDark
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFF00C853))
                        : (isDark
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFFF3D00));

                    return ValueListenableBuilder<double>(
                      valueListenable: _roiNotifier,
                      builder: (context, roiValue, child) => Text(
                        "${isProfit ? '+' : ''}${formatter.format(pnlValue)} (${roiValue.toStringAsFixed(2)}%)",
                        style: TextStyle(
                          color: pnlColor,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.captionFontSize,
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

  Widget _buildTimeDecayInfo(BuildContext context) {
    final expiryInfo = OptionCalculator.getExpiryInfo(
      widget.position.expiryDate,
    );

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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.tinySpacing,
        vertical: ResponsiveHelper.tinySpacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.cardBorderRadius * 0.2,
        ),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        expiryInfo.statusText,
        style: TextStyle(
          fontSize: ResponsiveHelper.tinyFontSize * 0.9,
          fontWeight: FontWeight.bold,
          color: urgencyColor,
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
          padding: EdgeInsets.all(ResponsiveHelper.cardPadding * 1.2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.layers_clear_outlined,
            size: ResponsiveHelper.iconSize * 2,
            color: theme.disabledColor,
          ),
        ),
        SizedBox(height: ResponsiveHelper.sectionSpacing),
        Text(
          "No Open F&O Positions",
          style: TextStyle(
            fontSize: ResponsiveHelper.h3FontSize,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: ResponsiveHelper.smallSpacing),
        Text(
          "Your options trades will appear here.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
            fontSize: ResponsiveHelper.captionFontSize,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
