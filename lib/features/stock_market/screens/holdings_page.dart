import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/features/stock_market/screens/buy_stock_page.dart';
import 'package:bullxchange/features/stock_market/screens/sell_stock_page.dart';
import 'package:bullxchange/widgets/trade_action_buttons.dart';

// ---------------------------------------------------------------------------
// 1. MAIN HOLDINGS PAGE
// ---------------------------------------------------------------------------
class HoldingsPage extends StatefulWidget {
  const HoldingsPage({super.key});

  @override
  State<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<List<StockHoldingModel>?>? _holdingsStream;

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _holdingsStream = _userService
          .streamUserProfile(uid)
          .map((profile) => profile?.stocks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_auth.currentUser?.uid == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              "Please log in to see your holdings.",
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<InstrumentProvider>(
      builder: (context, instrumentProvider, child) {
        return StreamBuilder<List<StockHoldingModel>?>(
          stream: _holdingsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Error fetching portfolio: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              );
            }

            final userHoldings = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            if (!isLoading && userHoldings != null && userHoldings.isNotEmpty) {
              instrumentProvider.fetchLiveDataForHoldings(userHoldings);
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  PortfolioSummaryCard(
                    holdings: userHoldings,
                    isLoading: isLoading,
                  ),

                  // Section Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Holdings (${userHoldings?.length ?? 0})",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color:
                              theme.textTheme.bodySmall?.color?.withOpacity(
                                0.8,
                              ) ??
                              colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),

                  if (isLoading)
                    const HoldingsListSkeleton()
                  else if (userHoldings == null || userHoldings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: HoldingsEmptyState(),
                    )
                  else
                    HoldingsList(holdings: userHoldings),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 2. HOLDINGS LIST WIDGET
// ---------------------------------------------------------------------------

class HoldingsList extends StatelessWidget {
  final List<StockHoldingModel> holdings;

  const HoldingsList({super.key, required this.holdings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: holdings.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          indent: 72, // Indent to bypass logo
          endIndent: 16,
          color: theme.dividerColor.withOpacity(0.15),
        ),
        itemBuilder: (context, index) {
          final holding = holdings[index];
          return PortfolioStockItem(
            key: ValueKey('${holding.stockSymbol}_$index'),
            holding: holding,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. PORTFOLIO STOCK ITEM (Realistic List Tile)
// ---------------------------------------------------------------------------
class PortfolioStockItem extends StatefulWidget {
  final StockHoldingModel holding;
  const PortfolioStockItem({super.key, required this.holding});

  @override
  State<PortfolioStockItem> createState() => _PortfolioStockItemState();
}

class _PortfolioStockItemState extends State<PortfolioStockItem> {
  final ValueNotifier<double> _ltpNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _plNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _percentNotifier = ValueNotifier(0.0);

  late final InstrumentProvider _provider;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<InstrumentProvider>(context, listen: false);

    _listener = () {
      if (!mounted) return;
      try {
        final inst = _provider.allNSEStocks.firstWhere(
          (i) => i.symbol.replaceAll('-EQ', '') == widget.holding.stockSymbol,
        );
        final ltp =
            (inst.liveData['ltp'] as num?)?.toDouble() ??
            widget.holding.transactionPrice;
        final avgPrice = widget.holding.transactionPrice;
        final q = widget.holding.quantity;
        final pl = (ltp - avgPrice) * q;
        final pct = avgPrice > 0 ? ((ltp - avgPrice) / avgPrice) * 100 : 0.0;

        _ltpNotifier.value = ltp;
        _plNotifier.value = pl;
        _percentNotifier.value = pct;
      } catch (_) {
        if (_ltpNotifier.value == 0.0) {
          final avgPrice = widget.holding.transactionPrice;
          _ltpNotifier.value = avgPrice;
          _plNotifier.value = 0.0;
          _percentNotifier.value = 0.0;
        }
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
    _percentNotifier.dispose();
    super.dispose();
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PortfolioStockItemDetailsSheet(
          holding: widget.holding,
          ltpNotifier: _ltpNotifier,
          plNotifier: _plNotifier,
          percentNotifier: _percentNotifier,
        );
      },
    );
  }

  Widget _buildLogoContainer(String name, ThemeData theme) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        // Subtle background in dark mode, distinct in light mode
        color: theme.brightness == Brightness.dark
            ? color.withOpacity(0.2)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? color
                      .withRed(255)
                      .withGreen(255)
                      .withBlue(255) // Lighter shade
                : color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final h = widget.holding;

    final Instrument? instrument = _provider.getInstrumentBySymbol(
      h.stockSymbol,
    );

    return InkWell(
      onTap: () => _showDetailsSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            if (instrument != null)
              SmartLogo(instrument: instrument, radius: 20)
            else
              _buildLogoContainer(h.stockName, theme),

            const SizedBox(width: 16),

            // Symbol & Quantity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.stockSymbol,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${h.quantity} shares • Avg. ${h.transactionPrice.toStringAsFixed(1)}",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Price & P&L
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _ltpNotifier,
                  builder: (_, val, __) => Text(
                    "₹${(val * h.quantity).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<double>(
                  valueListenable: _plNotifier,
                  builder: (_, plVal, __) => ValueListenableBuilder<double>(
                    valueListenable: _percentNotifier,
                    builder: (_, pctVal, __) {
                      final isPositive = plVal >= 0;
                      // Brighter green/red for Dark mode visibility
                      final color = isPositive
                          ? (theme.brightness == Brightness.dark
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF00C853))
                          : (theme.brightness == Brightness.dark
                                ? const Color(0xFFEF5350)
                                : const Color(0xFFFF3D00));

                      return Text(
                        "₹${plVal.abs().toStringAsFixed(2)} (${pctVal.abs().toStringAsFixed(2)}%)",
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
}

// ---------------------------------------------------------------------------
// 4. BOTTOM SHEET
// ---------------------------------------------------------------------------
class PortfolioStockItemDetailsSheet extends StatelessWidget {
  final StockHoldingModel holding;
  final ValueNotifier<double> ltpNotifier;
  final ValueNotifier<double> plNotifier;
  final ValueNotifier<double> percentNotifier;

  const PortfolioStockItemDetailsSheet({
    super.key,
    required this.holding,
    required this.ltpNotifier,
    required this.plNotifier,
    required this.percentNotifier,
  });

  static const Color primaryColor = Color(0xFF00C853);
  static const Color sellColor = Color(0xFFFF3D00);

  Widget _buildDetailRow(
    BuildContext context,
    String title,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Instrument? _getInstrument(BuildContext context) {
    final instrumentProvider = Provider.of<InstrumentProvider>(
      context,
      listen: false,
    );
    try {
      return instrumentProvider.allNSEStocks.firstWhere(
        (i) => i.symbol.replaceAll('-EQ', '') == holding.stockSymbol,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleSell(BuildContext context) async {
    final instrument = _getInstrument(context);
    if (instrument == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SellStockPage(instrument: instrument, userHolding: holding),
        ),
      );
    }
  }

  void _handleBuy(BuildContext context) {
    final instrument = _getInstrument(context);
    if (instrument == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuyStockPage(instrument: instrument),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final investedAmount = holding.transactionPrice * holding.quantity;
    final instrument = _getInstrument(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        // Soft glow for dark mode, shadow for light mode
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  if (instrument != null)
                    SmartLogo(instrument: instrument, radius: 24)
                  else
                    const CircleAvatar(child: Text("?")),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holding.stockName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          holding.stockSymbol,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                theme.textTheme.bodySmall?.color?.withOpacity(
                                  0.8,
                                ) ??
                                colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
              const SizedBox(height: 16),

              _buildDetailRow(context, "Quantity", "${holding.quantity}"),
              _buildDetailRow(
                context,
                "Avg. Price",
                "₹${holding.transactionPrice.toStringAsFixed(2)}",
              ),
              _buildDetailRow(
                context,
                "Invested",
                "₹${investedAmount.toStringAsFixed(2)}",
              ),
              ValueListenableBuilder<double>(
                valueListenable: ltpNotifier,
                builder: (_, ltp, __) => _buildDetailRow(
                  context,
                  "LTP",
                  "₹${ltp.toStringAsFixed(2)}",
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: plNotifier,
                builder: (_, pl, __) {
                  final color = pl >= 0 ? primaryColor : sellColor;
                  return _buildDetailRow(
                    context,
                    "Total Returns",
                    "₹${pl.abs().toStringAsFixed(2)}",
                    valueColor: color,
                  );
                },
              ),

              const SizedBox(height: 32),

              TradeActionButtons(
                onSell: () async => await _handleSell(context),
                onBuy: () => _handleBuy(context),
                sellLabel: 'SELL',
                buyLabel: 'BUY MORE',
                height: 56.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. SUMMARY CARD (Themed for Light/Dark)
// ---------------------------------------------------------------------------

class PortfolioSummaryCard extends StatelessWidget {
  final List<StockHoldingModel>? holdings;
  final bool isLoading;

  const PortfolioSummaryCard({
    super.key,
    this.holdings,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    if (isLoading || holdings == null) {
      return Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.all(16.0),
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey,
          ),
        ),
      );
    }

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        double currentValue = 0, investedValue = 0, dayReturns = 0;
        final holdingSymbols = holdings!.map((h) => h.stockSymbol).toSet();
        final liveInstruments = provider.allNSEStocks
            .where(
              (stock) =>
                  holdingSymbols.contains(stock.symbol.replaceAll('-EQ', '')),
            )
            .toList();

        for (var holding in holdings!) {
          Instrument? liveInstrument;
          try {
            liveInstrument = liveInstruments.firstWhere(
              (inst) =>
                  inst.symbol.replaceAll('-EQ', '') == holding.stockSymbol,
            );
          } catch (_) {}

          final ltp =
              (liveInstrument?.liveData['ltp'] as num?)?.toDouble() ??
              holding.transactionPrice;
          final netChange =
              (liveInstrument?.liveData['netChange'] as num?)?.toDouble() ??
              0.0;

          currentValue += ltp * holding.quantity;
          investedValue += holding.transactionPrice * holding.quantity;
          dayReturns += netChange * holding.quantity;
        }

        final totalReturns = currentValue - investedValue;
        final totalReturnPercent = investedValue > 0
            ? (totalReturns / investedValue) * 100
            : 0;
        final dayReturnPercent = investedValue > 0
            ? (dayReturns / investedValue) * 100
            : 0.0;

        // Determine Colors based on Brightness
        final cardBackground = isDark
            ? colorScheme
                  .surfaceContainer // Dark surface
            : Colors.white; // White surface

        final borderColor = isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.2);

        final List<BoxShadow> shadow = isDark
            ? <BoxShadow>[] // No shadow in dark mode
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: shadow,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            children: [
              // Top: Current Value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current Value",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${currentValue.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Total Returns Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (totalReturns >= 0 ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          totalReturns >= 0
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          color: totalReturns >= 0 ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        Text(
                          "${totalReturnPercent.abs().toStringAsFixed(2)}%",
                          style: TextStyle(
                            color: totalReturns >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
              const SizedBox(height: 16),

              // Bottom Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactMetric(
                    context,
                    "Invested Value",
                    "₹${investedValue.toStringAsFixed(2)}",
                  ),
                  _buildCompactMetric(
                    context,
                    "Day's Returns",
                    "₹${dayReturns.abs().toStringAsFixed(2)}",
                    valueColor: dayReturns >= 0
                        ? (isDark ? const Color(0xFF66BB6A) : Colors.green)
                        : (isDark ? const Color(0xFFEF5350) : Colors.red),
                    isPnl: true,
                    percent: dayReturnPercent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactMetric(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isPnl = false,
    double? percent,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isPnl)
              Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Text(
                  (percent ?? 0) >= 0 ? "+" : "-",
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 6. EMPTY STATES & SKELETONS
// ---------------------------------------------------------------------------
class HoldingsEmptyState extends StatelessWidget {
  const HoldingsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: theme.disabledColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No holdings found",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class HoldingsListSkeleton extends StatelessWidget {
  const HoldingsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700]! : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 100,
                          color: isDark ? Colors.grey[700]! : Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 60,
                          color: isDark ? Colors.grey[700]! : Colors.white,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: 12,
                        width: 80,
                        color: isDark ? Colors.grey[700]! : Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 50,
                        color: isDark ? Colors.grey[700]! : Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
