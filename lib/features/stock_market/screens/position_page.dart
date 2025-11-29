import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/services/firebase/charge_calculator_service.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:bullxchange/features/stock_market/screens/buy_stock_page.dart';
import 'package:bullxchange/features/stock_market/screens/sell_stock_page.dart';
import 'package:bullxchange/widgets/trade_action_buttons.dart';

// --- HELPER: Consistent Intraday Badge ---
Widget _buildIntradayBadge(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 10, color: Colors.blue),
        const SizedBox(width: 3),
        Text(
          "INTRADAY",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

// --- 1. MAIN PAGE ---
class PositionPage extends StatefulWidget {
  const PositionPage({super.key});

  @override
  State<PositionPage> createState() => _PositionPageState();
}

class _PositionPageState extends State<PositionPage> {
  final UserService _userService = UserService();
  final ChargeCalculatorService _chargeCalculator = ChargeCalculatorService();

  Future<void> _handleExitAllPositions(
    BuildContext context,
    List<StockHoldingModel> positions,
    InstrumentProvider provider,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit All Positions?'),
        content: Text(
          'Are you sure you want to sell all ${positions.length} intraday positions at market price?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Exit All', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    int successCount = 0;
    int errorCount = 0;
    try {
      for (var position in positions) {
        final instrument = provider.getInstrumentBySymbol(position.stockSymbol);
        if (instrument == null) {
          errorCount++;
          continue;
        }

        final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
        if (ltp == 0.0) {
          errorCount++;
          continue;
        }

        final quantity = position.quantity;
        final tradeValue = ltp * quantity;
        final charges = _chargeCalculator.calculateSellCharges(tradeValue);
        final totalAmount = tradeValue - (charges['total'] ?? 0.0);

        final newTransaction = TransactionModel(
          userId: uid,
          companyName: position.stockName,
          transactionType: 'SELL',
          quantity: quantity,
          price: ltp,
          charges: charges['total'] ?? 0.0,
          totalAmount: totalAmount,
          exchange: position.exchange,
          productType: 'Intraday',
          orderType: '',
          stockSymbol: '',
          transactionTime: DateTime.now(),
        );

        final holdingUpdate = StockHoldingModel(
          stockName: position.stockName,
          stockSymbol: position.stockSymbol,
          quantity: -quantity,
          transactionPrice: ltp,
          buyingTime: DateTime.now(),
          charges: charges['total'] ?? 0.0,
          totalAmount: totalAmount,
          exchange: position.exchange,
          transactionType: 'INTRADAY',
        );

        await _userService.executeTrade(
          uid: uid,
          transaction: newTransaction,
          stockHoldingUpdate: holdingUpdate,
        );
        successCount++;
      }
    } catch (e) {
      errorCount++;
    } finally {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: errorCount > 0 ? Colors.red : Colors.green,
            content: Text(
              'Exited $successCount positions. $errorCount failed.',
            ),
          ),
        );
      }
    }
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
            Text(
              "Please log in to see your positions.",
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer2<UserProfileDataModel?, InstrumentProvider>(
      builder: (context, userProfile, instrumentProvider, child) {
        if (userProfile == null || userProfile.positions.isEmpty) {
          return const Center(child: _EmptyState());
        }

        final userPositions = userProfile.positions;

        double totalOverallPnl = 0;
        double totalInvestment = 0;
        for (var position in userPositions) {
          final instrument = instrumentProvider.getInstrumentBySymbol(
            position.stockSymbol,
          );
          if (instrument == null) continue;
          final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
          final avgBuyPrice = position.transactionPrice;
          final quantity = position.quantity;
          final double pnl = (ltp - avgBuyPrice) * quantity;
          final double investment = avgBuyPrice * quantity;
          totalOverallPnl += pnl;
          totalInvestment += investment;
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              _buildPositionSummaryCard(
                context,
                totalOverallPnl,
                totalInvestment,
                onExitAll: () => _handleExitAllPositions(
                  context,
                  userPositions,
                  instrumentProvider,
                ),
              ),

              // Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Open Positions (${userPositions.length})",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    // --- UPDATED: VISIBLE INTRADAY BADGE IN HEADER ---
                    _buildIntradayBadge(context),
                  ],
                ),
              ),

              // Positions List
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userPositions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 72,
                  endIndent: 16,
                  color: theme.dividerColor.withOpacity(0.15),
                ),
                itemBuilder: (context, index) {
                  return PositionStockItem(
                    key: ValueKey(userPositions[index].stockSymbol),
                    position: userPositions[index],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPositionSummaryCard(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total P&L",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 10,
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
                          fontSize: 24,
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
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
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${totalInvestment.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 10,
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
                          fontSize: 10,
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
          "No Open Positions",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your intraday trades will appear here.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// --- 2. LIST ITEM ---
class PositionStockItem extends StatefulWidget {
  final StockHoldingModel position;
  const PositionStockItem({super.key, required this.position});

  @override
  State<PositionStockItem> createState() => _PositionStockItemState();
}

class _PositionStockItemState extends State<PositionStockItem> {
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
          (i) => i.symbol.replaceAll('-EQ', '') == widget.position.stockSymbol,
        );
        final ltp =
            (inst.liveData['ltp'] as num?)?.toDouble() ??
            widget.position.transactionPrice;
        final avgPrice = widget.position.transactionPrice;
        final q = widget.position.quantity;
        final pl = (ltp - avgPrice) * q;
        final pct = avgPrice > 0 ? ((ltp - avgPrice) / avgPrice) * 100 : 0.0;

        _ltpNotifier.value = ltp;
        _plNotifier.value = pl;
        _percentNotifier.value = pct;
      } catch (_) {
        if (_ltpNotifier.value == 0.0) {
          final avgPrice = widget.position.transactionPrice;
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
        return PositionStockItemDetailsSheet(
          position: widget.position,
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
                ? color.withRed(255).withGreen(255)
                : color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    final priceFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final Instrument? instrument = _provider.getInstrumentBySymbol(
      p.stockSymbol,
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showDetailsSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            if (instrument != null)
              SmartLogo(instrument: instrument, radius: 20)
            else
              _buildLogoContainer(p.stockName, theme),
            const SizedBox(width: 16),

            // Symbol & Qty
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.stockSymbol,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // --- UPDATED: VISIBLE INTRADAY BADGE IN LIST ---
                      _buildIntradayBadge(context),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${p.quantity} Qty",
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // P&L Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _ltpNotifier,
                  builder: (_, val, __) => Text(
                    priceFormatter.format(val * p.quantity),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
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
                      final sign = isPositive ? "+" : "-";

                      final color = isPositive
                          ? (isDark
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFF00C853))
                          : (isDark
                                ? const Color(0xFFEF5350)
                                : const Color(0xFFFF3D00));

                      return Text(
                        "$sign₹${plVal.abs().toStringAsFixed(2)} (${pctVal.abs().toStringAsFixed(2)}%)",
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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

// --- 3. BOTTOM SHEET ---
class PositionStockItemDetailsSheet extends StatelessWidget {
  final StockHoldingModel position;
  final ValueNotifier<double> ltpNotifier;
  final ValueNotifier<double> plNotifier;
  final ValueNotifier<double> percentNotifier;

  const PositionStockItemDetailsSheet({
    super.key,
    required this.position,
    required this.ltpNotifier,
    required this.plNotifier,
    required this.percentNotifier,
  });

  static const Color primaryColor = Color(0xFF00C853);
  static const Color sellColor = Color(0xFFFF3D00);

  Widget _buildDetailRow(
    BuildContext context,
    String title,
    Widget valueWidget,
  ) {
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
              fontSize: 10,
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildLogoContainer(String name, ThemeData theme) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? color.withOpacity(0.2)
            : color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? color.withRed(255).withGreen(255)
                : color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        (i) => i.symbol.replaceAll('-EQ', '') == position.stockSymbol,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleSell(BuildContext context) async {
    final instrument = _getInstrument(context);
    if (instrument == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not find live data for this stock."),
          ),
        );
      }
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to sell stocks.")),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SellStockPage(instrument: instrument, userHolding: position),
        ),
      );
    }
  }

  void _handleBuy(BuildContext context) {
    final instrument = _getInstrument(context);
    if (instrument == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not find live data for this stock to buy."),
          ),
        );
      }
      return;
    }

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
    final investedAmount = position.transactionPrice * position.quantity;
    final priceFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Instrument? instrument = _getInstrument(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (instrument != null)
                    SmartLogo(instrument: instrument, radius: 24)
                  else
                    _buildLogoContainer(position.stockName, theme),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.stockName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // --- UPDATED: VISIBLE INTRADAY BADGE IN BOTTOM SHEET ---
                        Row(
                          children: [
                            Text(
                              position.stockSymbol,
                              style: TextStyle(
                                color:
                                    theme.textTheme.bodySmall?.color ??
                                    colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildIntradayBadge(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
              const SizedBox(height: 16),

              _buildDetailRow(
                context,
                "Quantity",
                Text(
                  "${position.quantity} Shares",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              _buildDetailRow(
                context,
                "Invested Amount",
                Text(
                  priceFormatter.format(investedAmount),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              _buildDetailRow(
                context,
                "Current Price",
                ValueListenableBuilder<double>(
                  valueListenable: ltpNotifier,
                  builder: (_, ltpVal, __) => Text(
                    priceFormatter.format(ltpVal),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              _buildDetailRow(
                context,
                "Total P&L",
                ValueListenableBuilder<double>(
                  valueListenable: plNotifier,
                  builder: (_, plVal, __) {
                    final isPositive = plVal >= 0;
                    final sign = isPositive ? "+" : "-";
                    final color = isPositive ? primaryColor : sellColor;

                    return ValueListenableBuilder<double>(
                      valueListenable: percentNotifier,
                      builder: (_, pctVal, __) => Text(
                        "$sign₹${plVal.abs().toStringAsFixed(2)} ($sign${pctVal.abs().toStringAsFixed(2)}%)",
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              TradeActionButtons(
                onSell: () async => await _handleSell(context),
                onBuy: () => _handleBuy(context),
                sellLabel: 'EXIT',
                buyLabel: 'ADD MORE',
                height: 56.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
