import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';

// ⭐️ ADDED IMPORTS FOR NAVIGATION TARGETS
import 'package:bullxchange/features/stock_market/screens/buy_stock_page.dart';
import 'package:bullxchange/features/stock_market/screens/sell_stock_page.dart';
// ---------------------------------------------------------------------------

/// Holdings page with shimmer and live price updates.
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
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_auth.currentUser?.uid == null) {
      return Center(
        // --- ⭐️ MODIFIED: Theme text color ---
        child: Text(
          "Please log in to see your holdings.",
          style: TextStyle(color: colorScheme.onSurface),
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
                // --- ⭐️ MODIFIED: Theme error color ---
                child: Text(
                  "Error fetching portfolio: ${snapshot.error}",
                  style: TextStyle(color: colorScheme.error),
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
              child: Column(
                children: [
                  PortfolioSummaryCard(
                    // Yeh card ab hamesha gradient dikhega
                    holdings: userHoldings,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const HoldingsListSkeleton() // Yeh theme-aware hai
                  else if (userHoldings == null || userHoldings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48.0),
                        child: HoldingsEmptyState(), // Yeh theme-aware hai
                      ),
                    )
                  else
                    ...userHoldings.map(
                      (holding) => PortfolioStockItem(
                        // Yeh theme-aware hai
                        key: ValueKey(holding.stockSymbol),
                        holding: holding,
                      ),
                    ),
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
// 🪙 Empty State (Theme-Aware)
// ---------------------------------------------------------------------------

class HoldingsEmptyState extends StatelessWidget {
  const HoldingsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 48,
          // --- ⭐️ MODIFIED: Theme grey color ---
          color: textTheme.bodySmall?.color,
        ),
        const SizedBox(height: 16),
        Text(
          "Your Portfolio is Empty",
          // --- ⭐️ MODIFIED: Theme text color ---
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Buy your first stock to see your long-term holdings here.",
          // --- ⭐️ MODIFIED: Theme grey color ---
          style: TextStyle(color: textTheme.bodySmall?.color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// ⬇️ MODIFIED WIDGET: PortfolioStockItem (Theme-Aware)
// -----------------------------------------------------------------
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

  // New method to show the bottom sheet
  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Transparent banaya taaki sheet ka color theme se aaye
      builder: (context) {
        // Pass the ValueNotifiers to keep the details live-updating
        return PortfolioStockItemDetailsSheet(
          holding: widget.holding,
          ltpNotifier: _ltpNotifier,
          plNotifier: _plNotifier,
          percentNotifier: _percentNotifier,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final h = widget.holding;

    return GestureDetector(
      onTap: () => _showDetailsSheet(context),
      child: Container(
        // --- ⭐️ MODIFIED: Background color theme se ---
        // Isse tap effect poore row mein aayega
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            _buildLogoContainer(h.stockName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.stockSymbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      // --- ⭐️ MODIFIED: Theme text color ---
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "${h.quantity} shares",
                    // --- ⭐️ MODIFIED: Theme grey color ---
                    style: TextStyle(
                      color: textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _ltpNotifier,
                  builder: (_, val, __) => Text(
                    "₹${(val * h.quantity).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      // --- ⭐️ MODIFIED: Theme text color ---
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<double>(
                  valueListenable: _plNotifier,
                  builder: (_, plVal, __) => ValueListenableBuilder<double>(
                    valueListenable: _percentNotifier,
                    builder: (_, pctVal, __) {
                      final sign = plVal >= 0 ? "+" : "";
                      final color = plVal >= 0 ? Colors.green : Colors.red;
                      return Text(
                        "$sign₹${plVal.toStringAsFixed(2)} (${pctVal.toStringAsFixed(2)}%)",
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

  Widget _buildLogoContainer(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// 🌟 UPDATED WIDGET: PortfolioStockItemDetailsSheet (Theme-Aware)
// -----------------------------------------------------------------
// ... (file ka baaki code upar) ...

// -----------------------------------------------------------------
// 🌟 UPDATED WIDGET: PortfolioStockItemDetailsSheet (Fixed Button Colors)
// -----------------------------------------------------------------
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

  Widget _buildDetailRow(
    BuildContext context,
    String title,
    Widget valueWidget,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: textTheme.bodySmall?.color, fontSize: 16),
          ),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildLogoContainer(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
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
        (i) => i.symbol.replaceAll('-EQ', '') == holding.stockSymbol,
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
              SellStockPage(instrument: instrument, userHolding: holding),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final investedAmount = holding.transactionPrice * holding.quantity;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogoContainer(holding.stockName),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holding.stockName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          holding.stockSymbol,
                          style: TextStyle(
                            color: textTheme.bodySmall?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 30),

              _buildDetailRow(
                context,
                "Quantity",
                Text(
                  "${holding.quantity} Shares",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _buildDetailRow(
                context,
                "Invested Amount",
                Text(
                  "₹${investedAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _buildDetailRow(
                context,
                "Current Stock Price",
                ValueListenableBuilder<double>(
                  valueListenable: ltpNotifier,
                  builder: (_, ltpVal, __) => Text(
                    "₹${ltpVal.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              _buildDetailRow(
                context,
                "Current Profit (Value)",
                ValueListenableBuilder<double>(
                  valueListenable: plNotifier,
                  builder: (_, plVal, __) {
                    final sign = plVal >= 0 ? "+" : "";
                    final color = plVal >= 0 ? Colors.green : Colors.red;
                    final currentValue = ltpNotifier.value * holding.quantity;

                    return ValueListenableBuilder<double>(
                      valueListenable: percentNotifier,
                      builder: (_, pctVal, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${currentValue.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$sign₹${plVal.toStringAsFixed(2)} (${pctVal.toStringAsFixed(2)}%)",
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 30),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleBuy(context),
                      style: ElevatedButton.styleFrom(
                        // --- ⭐️ MODIFIED: Hardcoded Pink for BUY button ---
                        backgroundColor: const Color(0xFFDB1B57),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        // ⭐️ Changed to const for `Text`
                        "BUY",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ), // Always white text
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async => await _handleSell(context),
                      style: ElevatedButton.styleFrom(
                        // --- ⭐️ MODIFIED: Hardcoded Dark Blue for SELL button ---
                        backgroundColor: const Color(
                          0xFF1A237E,
                        ), // A darker blue
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        // ⭐️ Changed to const for `Text`
                        "SELL",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ), // Always white text
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------
// ⬆️ UPDATED WIDGET: PortfolioStockItemDetailsSheet
// -----------------------------------------------------------------

// -----------------------------------------------------------------
// ⬇️ MODIFIED WIDGET: HoldingsListSkeleton (Theme-Aware)
// -----------------------------------------------------------------
class HoldingsListSkeleton extends StatelessWidget {
  const HoldingsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      // --- ⭐️ MODIFIED: Theme-aware shimmer ---
      baseColor: theme.brightness == Brightness.light
          ? Colors.grey[300]!
          : Colors.grey[800]!,
      highlightColor: theme.brightness == Brightness.light
          ? Colors.grey[100]!
          : Colors.grey[700]!,
      child: Column(
        children: List.generate(4, (_) => const SkeletonStockItem()),
      ),
    );
  }
}

// -----------------------------------------------------------------
// ⬇️ MODIFIED WIDGET: SkeletonStockItem (Theme-Aware)
// -----------------------------------------------------------------
class SkeletonStockItem extends StatelessWidget {
  const SkeletonStockItem({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    // --- ⭐️ MODIFIED: Theme-aware shimmer shape color ---
    final baseColor = theme.brightness == Brightness.light
        ? Colors.white
        : Colors.grey.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: baseColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 16, color: baseColor),
                const SizedBox(height: 4),
                Container(width: 60, height: 12, color: baseColor),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 30,
            color: baseColor,
          ), // Placeholder for chart?
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 70, height: 16, color: baseColor),
              const SizedBox(height: 4),
              Container(width: 90, height: 12, color: baseColor),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// ⬇️ MODIFIED WIDGET: PortfolioSummaryCard (Shimmer Theme-Aware, Gradient Hardcoded)
// -----------------------------------------------------------------
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
    // --- ⭐️ Theme se colors lo (Sirf shimmer ke liye) ---
    final theme = Theme.of(context);

    if (isLoading || holdings == null) {
      return Shimmer.fromColors(
        // --- ⭐️ MODIFIED: Theme-aware shimmer ---
        baseColor: theme.brightness == Brightness.light
            ? Colors.grey[300]!
            : Colors.grey[800]!,
        highlightColor: theme.brightness == Brightness.light
            ? Colors.grey[100]!
            : Colors.grey[700]!,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // --- ⭐️ MODIFIED: Theme-aware shimmer shape color ---
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : Colors.grey.shade800,
            ),
          ),
        ),
      );
    }

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // ... (Calculation logic unchanged) ...
        double currentValue = 0,
            investedValue = 0,
            dayReturns = 0,
            startOfDayValue = 0;
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
          } catch (e) {
            liveInstrument = null;
          }

          final ltp =
              (liveInstrument?.liveData['ltp'] as num?)?.toDouble() ??
              holding.transactionPrice;
          final netChange =
              (liveInstrument?.liveData['netChange'] as num?)?.toDouble() ??
              0.0;
          final previousClose = ltp - netChange;

          currentValue += ltp * holding.quantity;
          investedValue += holding.transactionPrice * holding.quantity;
          dayReturns += netChange * holding.quantity;
          startOfDayValue += previousClose * holding.quantity;
        }

        final totalReturns = currentValue - investedValue;
        final totalReturnPercent = investedValue > 0
            ? (totalReturns / investedValue) * 100
            : 0;
        final dayReturnPercent = startOfDayValue > 0
            ? (dayReturns / startOfDayValue) * 100
            : 0.0;

        return _buildSummaryCardUI(
          currentValue,
          totalReturns,
          totalReturnPercent.toDouble(),
          investedValue,
          dayReturns,
          dayReturnPercent,
        );
      },
    );
  }

  // --- ⭐️ MODIFIED: Yeh widget ab hardcoded gradient use karega (jaisa aapne kaha) ---
  Widget _buildSummaryCardUI(
    double cVal,
    double tRet,
    double tRetPct,
    double iVal,
    double dRet,
    double dRetPct,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // --- ⭐️ UNCHANGED: Hardcoded gradient (jaisa aapne kaha) ---
        gradient: const LinearGradient(
          colors: [Color(0xFF6F4CFF), Color(0xFFDB1B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = constraints.maxWidth;
          final double titleSize = cardWidth < 340 ? 12.0 : 13.0;
          final double valueSize = cardWidth < 340 ? 14.0 : 16.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryColumn(
                      "Current",
                      cVal,
                      titleFontSize: titleSize,
                      valueFontSize: valueSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryColumn(
                      "Total returns",
                      tRet,
                      percent: tRetPct,
                      isReturn: true,
                      titleFontSize: titleSize,
                      valueFontSize: valueSize,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryColumn(
                      "Invested",
                      iVal,
                      titleFontSize: titleSize,
                      valueFontSize: valueSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryColumn(
                      "1D returns",
                      dRet,
                      percent: dRetPct,
                      isReturn: true,
                      titleFontSize: titleSize,
                      valueFontSize: valueSize,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // --- ⭐️ UNCHANGED: Hardcoded white text (gradient pe kaam karega) ---
  Widget _buildSummaryColumn(
    String title,
    double value, {
    double? percent,
    bool isReturn = false,
    double titleFontSize = 13.0,
    double valueFontSize = 16.0,
  }) {
    final sign = value >= 0 ? "+" : "";
    final Color badgeColor = value >= 0 ? Colors.greenAccent : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: titleFontSize,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isReturn
                      ? "$sign₹${value.toStringAsFixed(2)}"
                      : "₹${value.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isReturn && percent != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$sign${percent.toStringAsFixed(2)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
