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

// --- ⭐️ 1. CONVERTED TO STATEFUL WIDGET ---
class PositionPage extends StatefulWidget {
  const PositionPage({super.key});

  @override
  State<PositionPage> createState() => _PositionPageState();
}

class _PositionPageState extends State<PositionPage> {
  // --- ⭐️ 2. ADDED SERVICE INSTANCES ---
  final UserService _userService = UserService();
  final ChargeCalculatorService _chargeCalculator = ChargeCalculatorService();

  // --- ⭐️ 3. "EXIT ALL" FUNCTION ---
  Future<void> _handleExitAllPositions(
    BuildContext context, // Need context for dialogs
    List<StockHoldingModel> positions,
    InstrumentProvider provider,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // --- Step 1: Show Confirmation Dialog ---
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

    // If user did not confirm, do nothing
    if (confirm != true) return;

    // --- Step 2: Show Loading Dialog ---
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    // --- Step 3: Loop and Execute Trades ---
    int successCount = 0;
    int errorCount = 0;
    try {
      for (var position in positions) {
        final instrument = provider.getInstrumentBySymbol(position.stockSymbol);
        if (instrument == null) {
          errorCount++;
          continue; // Skip if no live data
        }

        final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
        if (ltp == 0.0) {
          errorCount++; // Can't sell at price 0
          continue;
        }

        final quantity = position.quantity;
        final tradeValue = ltp * quantity;
        final charges = _chargeCalculator.calculateSellCharges(tradeValue);
        final totalAmount = tradeValue - (charges['total'] ?? 0.0);

        // Create the Sell Transaction
        final newTransaction = TransactionModel(
          userId: uid,
          symbol: position.stockSymbol,
          companyName: position.stockName,
          transactionType: 'SELL',
          quantity: quantity,
          price: ltp,
          charges: charges['total'] ?? 0.0,
          totalAmount: totalAmount,
          executedAt: DateTime.now(),
          exchange: position.exchange,
          productType: 'Intraday',
          orderType: '', // Force Intraday
        );

        // Create the holding update (negative quantity)
        final holdingUpdate = StockHoldingModel(
          stockName: position.stockName,
          stockSymbol: position.stockSymbol,
          quantity: -quantity, // Negative quantity to remove from list
          transactionPrice: ltp,
          buyingTime: DateTime.now(),
          charges: charges['total'] ?? 0.0,
          totalAmount: totalAmount,
          exchange: position.exchange,
          transactionType: 'INTRADAY', // Must match 'INTRADAY'
        );

        // Call your existing executeTrade function
        await _userService.executeTrade(
          uid: uid,
          transaction: newTransaction,
          stockHoldingUpdate: holdingUpdate,
        );
        successCount++;
      }
    } catch (e) {
      errorCount++;
      // Handle error (e.g., log it)
    } finally {
      // --- Step 4: Close Loading Dialog and Show Result ---
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
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
    // --- ⭐️ ADDED AUTH CHECK ---
    final _auth = FirebaseAuth.instance;
    if (_auth.currentUser?.uid == null) {
      return const Center(child: Text("Please log in to see your positions."));
    }

    return Consumer2<UserProfileDataModel?, InstrumentProvider>(
      builder: (context, userProfile, instrumentProvider, child) {
        if (userProfile == null || userProfile.positions.isEmpty) {
          return Center(child: const _EmptyState());
        }

        final userPositions = userProfile.positions;

        // --- P&L Calculation (Unchanged) ---
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // --- ⭐️ 4. PASS THE FUNCTION TO THE CARD ---
                child: _buildPositionSummaryCard(
                  totalOverallPnl,
                  totalInvestment,
                  onExitAll: () => _handleExitAllPositions(
                    context,
                    userPositions,
                    instrumentProvider,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Intraday Positions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...userPositions.map((position) {
                return PositionStockItem(
                  key: ValueKey(position.stockSymbol),
                  position: position,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// --- _EmptyState (UNCHANGED) ---
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Icon(Icons.work_history_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "No Open Positions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Your intraday trades for the day will appear here.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// --- ⭐️ 5. MODIFIED _buildPositionSummaryCard ---
Widget _buildPositionSummaryCard(
  double totalPnl,
  double totalInvestment, {
  required VoidCallback onExitAll, // <-- Added callback
}) {
  // ⭐️ CHANGED: Use + for positive and - for negative
  final sign = totalPnl >= 0 ? "+" : "-";
  final color = totalPnl >= 0 ? Colors.greenAccent : Colors.redAccent;

  double totalPnlPercent = 0.0;
  if (totalInvestment > 0) {
    totalPnlPercent = (totalPnl / totalInvestment) * 100;
  }

  return Container(
    height: 170,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF6F4CFF), Color(0xFFDB1B57)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total Profit & Loss",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              // ⭐️ CHANGED: Use .abs() to avoid double signs (e.g., "-₹-50")
              "$sign₹${totalPnl.abs().toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                // ⭐️ CHANGED: Use .abs() here too for consistency
                "$sign${totalPnlPercent.abs().toStringAsFixed(2)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Exit all"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onExitAll, // <-- Use the passed callback
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// -----------------------------------------------------------------
// ⬇️ PositionStockItem and PositionStockItemDetailsSheet
// (UNCHANGED from your provided code, as they are correct)
// -----------------------------------------------------------------
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

    return GestureDetector(
      onTap: () => _showDetailsSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            if (instrument != null)
              SmartLogo(instrument: instrument, radius: 0)
            else
              _buildLogoContainer(p.stockName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.stockSymbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${p.quantity} shares",
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
                    priceFormatter.format(val * p.quantity),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<double>(
                  valueListenable: _plNotifier,
                  builder: (_, plVal, __) => ValueListenableBuilder<double>(
                    valueListenable: _percentNotifier,
                    builder: (_, pctVal, __) {
                      // ⭐️ CHANGED: Use + for positive and - for negative
                      final sign = plVal >= 0 ? "+" : "-";
                      final color = plVal >= 0 ? Colors.green : Colors.red;
                      return Text(
                        // ⭐️ CHANGED: Apply .abs() to both values and use the sign
                        "$sign₹${plVal.abs().toStringAsFixed(2)} ($sign${pctVal.abs().toStringAsFixed(2)}%)",
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

  static const Color primaryPink = Color(0xFFF61C7A);
  static const Color primaryBlue = Color(0xFF3500D4);

  Widget _buildDetailRow(String title, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildLogoContainer(String name, {double radius = 25}) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius,
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
          builder: (context) => SellStockPage(
            instrument: instrument,
            userHolding: position, // Pass the Intraday position
          ),
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

    final Instrument? instrument = _getInstrument(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  if (instrument != null)
                    SmartLogo(instrument: instrument, radius: 25)
                  else
                    _buildLogoContainer(position.stockName, radius: 25),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.stockName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          position.stockSymbol,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 30),
              _buildDetailRow(
                "Quantity",
                Text(
                  "${position.quantity} Shares",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDetailRow(
                "Invested Amount",
                Text(
                  priceFormatter.format(investedAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDetailRow(
                "Current Stock Price",
                ValueListenableBuilder<double>(
                  valueListenable: ltpNotifier,
                  builder: (_, ltpVal, __) => Text(
                    priceFormatter.format(ltpVal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildDetailRow(
                "Current Profit (Value)",
                ValueListenableBuilder<double>(
                  valueListenable: plNotifier,
                  builder: (_, plVal, __) {
                    // ⭐️ CHANGED: Use + for positive and - for negative
                    final sign = plVal >= 0 ? "+" : "-";
                    final color = plVal >= 0 ? Colors.green : Colors.red;
                    final currentValue = ltpNotifier.value * position.quantity;

                    return ValueListenableBuilder<double>(
                      valueListenable: percentNotifier,
                      builder: (_, pctVal, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            priceFormatter.format(currentValue),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // ⭐️ CHANGED: Apply .abs() to both values and use the sign
                            "$sign₹${plVal.abs().toStringAsFixed(2)} ($sign${pctVal.abs().toStringAsFixed(2)}%)",
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
                        backgroundColor: primaryPink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "BUY",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async => await _handleSell(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "SELL",
                        style: TextStyle(fontSize: 16, color: Colors.white),
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