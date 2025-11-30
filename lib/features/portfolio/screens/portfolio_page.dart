import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  // --- STATE VARIABLES ---
  final UserService _userService = UserService();
  late Stream<List<TransactionModel>> _transactionStream;
  late Stream<UserProfileDataModel?>
  _userProfileStream; // 1. Defined Stream variable
  String _currentUid = "";
  List<String> _lastHoldingSymbols = [];
  int _selectedSegment = 0; // 0 = Stocks, 1 = F&O

  @override
  void initState() {
    super.initState();
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    _currentUid = firebaseUser?.uid ?? "";

    // 2. Initialize Streams in initState (FIXES FLICKERING)
    if (_currentUid.isNotEmpty) {
      _transactionStream = _userService.streamRecentTransactions(_currentUid);
      _userProfileStream = _userService.streamUserProfile(_currentUid);
    } else {
      _transactionStream = Stream.value([]);
      _userProfileStream = Stream.value(null);
    }
  }

  void _updateHoldingsLiveData(List<StockHoldingModel> holdings) {
    final symbols = holdings.map((h) => h.stockSymbol).toList();
    // Only fetch if symbols list actually changed to prevent loops
    if (listEquals(symbols, _lastHoldingSymbols)) {
      return;
    }
    _lastHoldingSymbols = symbols;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InstrumentProvider>().fetchLiveDataForHoldings(holdings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- Colors Matching PositionPage ---
    final Color backgroundColor = isDark
        ? Colors.black
        : const Color(0xFFF2F2F7);
    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = theme.textTheme.bodyLarge!.color!;
    final Color subTextColor = const Color(0xFF8E8E93);

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    const Color kGreen = Color(0xFF34C759);
    const Color kRed = Color(0xFFFF3B30);
    const Color kBlue = Color(0xFF007AFF);

    if (_currentUid.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            "Please login to view portfolio",
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
      );
    }

    // 3. Use the initialized stream variable
    return StreamBuilder<UserProfileDataModel?>(
      stream: _userProfileStream,
      builder: (context, snapshot) {
        // Show loader only on initial load, not on updates
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator(color: kBlue)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: Text(
                "Profile Not Found",
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          );
        }

        final userProfile = snapshot.data!;
        final allHoldings = userProfile.stocks;
        final availableCash = userProfile.availableFunds;

        if (allHoldings.isNotEmpty) {
          _updateHoldingsLiveData(allHoldings);
        }

        return Consumer<InstrumentProvider>(
          builder: (context, instrumentProvider, child) {
            // --- DATA PROCESSING ---
            final List<Map<String, dynamic>> stockList = [];
            final List<Map<String, dynamic>> fnoList = [];

            double totalEquityCurrent = 0;
            double totalEquityInvested = 0;
            double totalFnoCurrent = 0;
            double totalFnoInvested = 0;
            double todaysTotalPL = 0;

            for (var holding in allHoldings) {
              final instrument = instrumentProvider.getInstrumentBySymbol(
                holding.stockSymbol,
              );
              final double currentPrice =
                  (instrument?.liveData['ltp'] as num?)?.toDouble() ??
                  holding.transactionPrice;
              final double yesterdayClose =
                  (instrument?.liveData['close'] as num?)?.toDouble() ??
                  currentPrice;

              double currentVal = holding.quantity * currentPrice;
              double investedVal = holding.quantity * holding.transactionPrice;
              double dayPL = (currentPrice - yesterdayClose) * holding.quantity;

              todaysTotalPL += dayPL;

              final holdingData = {
                'symbol': holding.stockSymbol,
                'quantity': holding.quantity,
                'avgBuyPrice': holding.transactionPrice,
                'currentPrice': currentPrice,
                'companyName': holding.stockName,
                'currentVal': currentVal,
                'investedVal': investedVal,
              };

              // Identify F&O vs Equity
              bool isFno =
                  holding.stockSymbol.endsWith("CE") ||
                  holding.stockSymbol.endsWith("PE");

              if (isFno) {
                fnoList.add(holdingData);
                totalFnoCurrent += currentVal;
                totalFnoInvested += investedVal;
              } else {
                stockList.add(holdingData);
                totalEquityCurrent += currentVal;
                totalEquityInvested += investedVal;
              }
            }

            // --- AGGREGATED TOTALS ---
            double totalPortfolioValue =
                availableCash + totalEquityCurrent + totalFnoCurrent;
            double totalInvested = totalEquityInvested + totalFnoInvested;
            double totalEquityPL = totalEquityCurrent - totalEquityInvested;
            double totalFnoPL = totalFnoCurrent - totalFnoInvested;
            double overallPL = totalEquityPL + totalFnoPL;
            double overallPLPercent = (totalInvested > 0)
                ? (overallPL / totalInvested) * 100
                : 0.0;

            final currentDisplayList = _selectedSegment == 0
                ? stockList
                : fnoList;

            return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: backgroundColor,
                scrolledUnderElevation: 0,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  "Portfolio",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // --- 1. TOTAL VALUE CARD ---
                    _buildSummaryCard(
                      totalPortfolioValue,
                      todaysTotalPL,
                      totalInvested,
                      availableCash,
                      overallPL,
                      overallPLPercent,
                      cardColor,
                      textColor,
                      subTextColor,
                      currency,
                      kGreen,
                      kRed,
                    ),

                    const SizedBox(height: 24),

                    // --- 2. SMOOTH TAB SWITCHER ---
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: subTextColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              title: "Stocks",
                              isSelected: _selectedSegment == 0,
                              onTap: () => setState(() => _selectedSegment = 0),
                              activeColor: kBlue,
                              textColor: textColor,
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              title: "F&O",
                              isSelected: _selectedSegment == 1,
                              onTap: () => setState(() => _selectedSegment = 1),
                              activeColor: kBlue,
                              textColor: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- 3. HOLDINGS LIST ---
                    _buildSectionHeader(
                      _selectedSegment == 0
                          ? "Holdings (${stockList.length})"
                          : "Positions (${fnoList.length})",
                      subTextColor,
                    ),

                    // Smooth Size Animation when switching lists
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: currentDisplayList.isEmpty
                          ? _buildEmptyState(
                              _selectedSegment == 0
                                  ? "No Active Holdings"
                                  : "No Active F&O Positions",
                              cardColor,
                              subTextColor,
                            )
                          : _buildHoldingsList(
                              currentDisplayList,
                              currency,
                              cardColor,
                              textColor,
                              subTextColor,
                              kGreen,
                              kRed,
                            ),
                    ),

                    const SizedBox(height: 24),

                    // --- 4. ALLOCATION CHART (Stocks Only) ---
                    if (_selectedSegment == 0 && totalEquityCurrent > 0) ...[
                      _buildSectionHeader("Asset Allocation", subTextColor),
                      _buildAllocationChart(
                        totalEquityCurrent,
                        availableCash,
                        cardColor,
                        textColor,
                        subTextColor,
                        kBlue,
                        kGreen,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- 5. RECENT ACTIVITY ---
                    _buildSectionHeader("Recent Activity", subTextColor),
                    _buildRecentTransactionsStream(
                      currency,
                      cardColor,
                      textColor,
                      subTextColor,
                      kGreen,
                      kRed,
                      _selectedSegment,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : textColor.withOpacity(0.6),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, Color cardColor, Color subTextColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.layers_clear_outlined,
            size: 40,
            color: subTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: subTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    double totalValue,
    double todaysPL,
    double invested,
    double cash,
    double overallPL,
    double plPercent,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    NumberFormat currency,
    Color kGreen,
    Color kRed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Total Portfolio Value",
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(totalValue),
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (todaysPL >= 0 ? kGreen : kRed).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  todaysPL >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: todaysPL >= 0 ? kGreen : kRed,
                ),
                const SizedBox(width: 4),
                Text(
                  "Today: ${currency.format(todaysPL.abs())}",
                  style: TextStyle(
                    color: todaysPL >= 0 ? kGreen : kRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                "Invested",
                invested,
                textColor,
                subTextColor,
                currency,
              ),
              _buildStatItem(
                "Cash Balance",
                cash,
                textColor,
                subTextColor,
                currency,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Overall Returns",
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${overallPL >= 0 ? '+' : ''}${currency.format(overallPL)}",
                    style: TextStyle(
                      color: overallPL >= 0 ? kGreen : kRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    double value,
    Color textColor,
    Color subTextColor,
    NumberFormat currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          currency.format(value),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingsList(
    List<Map<String, dynamic>> holdings,
    NumberFormat currency,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color kGreen,
    Color kRed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: holdings.length,
        separatorBuilder: (ctx, idx) => Divider(
          height: 1,
          thickness: 0.5,
          indent: 60,
          endIndent: 16,
          color: subTextColor.withOpacity(0.15),
        ),
        itemBuilder: (context, index) {
          final stock = holdings[index];
          final double profitLoss = stock['currentVal'] - stock['investedVal'];
          final bool isProfit = profitLoss >= 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  stock['symbol'][0],
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              stock['symbol'],
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "${stock['quantity']} Qty • Avg ${currency.format(stock['avgBuyPrice'])}",
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(stock['currentVal']),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${isProfit ? '+' : ''}${currency.format(profitLoss)}",
                  style: TextStyle(
                    color: isProfit ? kGreen : kRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentTransactionsStream(
    NumberFormat currency,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color kGreen,
    Color kRed,
    int selectedSegment,
  ) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionStream,
      builder: (context, snapshot) {
        // Only show spinner if initial load
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final allTransactions = snapshot.data ?? [];

        final filteredTransactions = allTransactions.where((txn) {
          bool isFnoTxn =
              txn.stockSymbol.endsWith("CE") || txn.stockSymbol.endsWith("PE");
          if (selectedSegment == 1) return isFnoTxn;
          return !isFnoTxn;
        }).toList();

        // Used AnimatedSize for smooth height changes instead of AnimatedSwitcher which causes opacity flash
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: filteredTransactions.isEmpty
              ? _buildEmptyState(
                  selectedSegment == 0
                      ? "No recent stock orders"
                      : "No recent F&O trades",
                  cardColor,
                  subTextColor,
                )
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filteredTransactions.length > 10
                        ? 10
                        : filteredTransactions.length,
                    separatorBuilder: (ctx, idx) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 60,
                      endIndent: 16,
                      color: subTextColor.withOpacity(0.15),
                    ),
                    itemBuilder: (context, index) {
                      final txn = filteredTransactions[index];
                      final bool isBuy =
                          txn.transactionType.toUpperCase() == "BUY";
                      final String txnTime = DateFormat(
                        'd MMM, HH:mm',
                      ).format(txn.transactionTime);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsPage(
                                transaction: txn,
                                transactionId: txn.id ?? "Unknown ID",
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (isBuy ? kGreen : kRed).withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isBuy
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isBuy ? kGreen : kRed,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txn.stockSymbol,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${txn.quantity} Qty • $txnTime",
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currency.format(txn.totalAmount),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: subTextColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isBuy ? "BUY" : "SELL",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isBuy ? kGreen : kRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAllocationChart(
    double equity,
    double cash,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color stockColor,
    Color cashColor,
  ) {
    if (equity <= 0 && cash <= 0) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                startDegreeOffset: -90,
                sections: [
                  if (equity > 0)
                    PieChartSectionData(
                      value: equity,
                      color: stockColor,
                      radius: 15,
                      showTitle: false,
                    ),
                  if (cash > 0)
                    PieChartSectionData(
                      value: cash,
                      color: cashColor,
                      radius: 15,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  "Stocks Investment",
                  equity,
                  stockColor,
                  textColor,
                  subTextColor,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  "Available Cash",
                  cash,
                  cashColor,
                  textColor,
                  subTextColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String title,
    double value,
    Color color,
    Color textColor,
    Color subTextColor,
  ) {
    final currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: subTextColor, fontSize: 11)),
            Text(
              currency.format(value),
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
