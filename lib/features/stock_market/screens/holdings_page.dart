import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';

/// Holdings page with shimmer and live price updates.
class HoldingsPage extends StatefulWidget {
  const HoldingsPage({super.key});

  @override
  State<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- FIX 1: Change Future to Stream ---
  Stream<List<StockHoldingModel>?>? _holdingsStream;
  // bool _liveDataFetched = false; // <-- This is no longer needed

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      // --- FIX 2: Use the new streamUserProfile method ---
      // We map the stream to only return the list of stocks.
      _holdingsStream = _userService
          .streamUserProfile(uid)
          .map((profile) => profile?.stocks);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser?.uid == null) {
      return const Center(child: Text("Please log in to see your holdings."));
    }

    // Using Consumer here to get the provider safely.
    return Consumer<InstrumentProvider>(
      builder: (context, instrumentProvider, child) {
        // --- FIX 3: Change FutureBuilder to StreamBuilder ---
        return StreamBuilder<List<StockHoldingModel>?>(
          stream: _holdingsStream, // Use the stream
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error fetching portfolio: ${snapshot.error}"),
              );
            }

            final userHoldings = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            // --- FIX 4: Fetch live data every time holdings update ---
            // We removed the _liveDataFetched flag. This ensures that
            // when the user buys/sells and this stream updates,
            // we re-fetch live data for the *new* list of holdings.
            if (!isLoading && userHoldings != null && userHoldings.isNotEmpty) {
              instrumentProvider.fetchLiveDataForHoldings(userHoldings);
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  PortfolioSummaryCard(
                    holdings: userHoldings,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const HoldingsListSkeleton()
                  else if (userHoldings == null || userHoldings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48.0),
                        child: Text("Your portfolio is empty."),
                      ),
                    )
                  else
                    ...userHoldings.map(
                      (holding) => PortfolioStockItem(
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

// ... (HoldingsListSkeleton is unchanged and correct) ...
class HoldingsListSkeleton extends StatelessWidget {
  const HoldingsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(4, (_) => const SkeletonStockItem()),
      ),
    );
  }
}

// ... (SkeletonStockItem is unchanged and correct) ...
class SkeletonStockItem extends StatelessWidget {
  const SkeletonStockItem({super.key});

  @override
  Widget build(BuildContext context) {
    Color baseColor = Colors.white;
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
          Container(width: 60, height: 30, color: baseColor),
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

// ... (PortfolioSummaryCard is unchanged and correct) ...
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
    if (isLoading || holdings == null) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
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
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6F4CFF), Color(0xFFDB1B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryColumn("Current", cVal),
              _buildSummaryColumn(
                "Total returns",
                tRet,
                percent: tRetPct,
                isReturn: true,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryColumn("Invested", iVal),
              _buildSummaryColumn(
                "1D returns",
                dRet,
                percent: dRetPct,
                isReturn: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(
    String title,
    double value, {
    double? percent,
    bool isReturn = false,
  }) {
    final sign = value >= 0 ? "+" : "";
    final color = value >= 0 ? Colors.greenAccent : Colors.redAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isReturn
                  ? "$sign₹${value.toStringAsFixed(2)}"
                  : "₹${value.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isReturn && percent != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$sign${percent.toStringAsFixed(2)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

// ... (PortfolioStockItem is unchanged and correct) ...
// This widget is already set up perfectly for your requests.
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

  @override
  Widget build(BuildContext context) {
    final h = widget.holding;

    return Padding(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "${h.quantity} shares",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
