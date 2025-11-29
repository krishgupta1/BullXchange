import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final UserService _userService = UserService();
  late Stream<List<TransactionModel>> _transactionStream;
  String _currentUid = "";

  // 0 = Stocks, 1 = F&O
  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    _currentUid = firebaseUser?.uid ?? "";

    if (_currentUid.isNotEmpty) {
      _transactionStream = _userService.streamRecentTransactions(_currentUid);
    } else {
      _transactionStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- Colors Matching Your UI ---
    final Color backgroundColor = isDark
        ? Colors.black
        : const Color(0xFFF2F2F7);
    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = theme.textTheme.bodyLarge!.color!;
    final Color subTextColor = const Color(0xFF8E8E93);

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    const Color kGreen = Color(0xFF34C759);
    const Color kRed = Color(0xFFFF3B30);
    const Color kBlue = Color(0xFF007AFF);

    if (_currentUid.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            "Please login to view portfolio",
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    return StreamBuilder<UserProfileDataModel?>(
      stream: _userService.streamUserProfile(_currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                style: TextStyle(color: textColor),
              ),
            ),
          );
        }

        final userProfile = snapshot.data!;
        final allHoldings = userProfile.stocks;
        final availableCash = userProfile.availableFunds;

        // Fetch live data for all holdings
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<InstrumentProvider>(
            context,
            listen: false,
          ).fetchLiveDataForHoldings(allHoldings);
        });

        return Consumer<InstrumentProvider>(
          builder: (context, instrumentProvider, child) {
            // --- DATA PROCESSING & SEPARATION ---

            final List<Map<String, dynamic>> stockList = [];
            final List<Map<String, dynamic>> fnoList = [];

            double totalEquityCurrent = 0;
            double totalEquityInvested = 0;

            double totalFnoCurrent = 0;
            double totalFnoInvested = 0;

            double todaysTotalPL = 0; // Combined P&L for today

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

              // --- TODO: F&O LOGIC HERE ---
              // Adjust this logic to match how you identify F&O in your database
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

            // --- COMMON CALCULATIONS (Aggregated) ---
            double totalPortfolioValue =
                availableCash + totalEquityCurrent + totalFnoCurrent;
            double totalInvested = totalEquityInvested + totalFnoInvested;

            double totalEquityPL = totalEquityCurrent - totalEquityInvested;
            double totalFnoPL = totalFnoCurrent - totalFnoInvested;
            double overallPL = totalEquityPL + totalFnoPL; // Net P&L

            double overallPLPercent = (totalInvested > 0)
                ? (overallPL / totalInvested) * 100
                : 0.0;

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
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: textColor),
                    onPressed: () {},
                  ),
                ],
              ),
              body: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // --- 1. COMMON TOP HEADER (Total Value) ---
                    _buildSectionHeader("Overview", subTextColor),
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

                    // --- 2. TOGGLE SWITCH (Stocks | F&O) ---
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

                    // --- 3. DYNAMIC CONTENT BASED ON SELECTION ---
                    if (_selectedSegment == 0) ...[
                      // STOCKS CONTENT
                      _buildSectionHeader(
                        "Holdings (${stockList.length})",
                        subTextColor,
                        trailing: "See All",
                      ),
                      _buildHoldingsList(
                        stockList,
                        currency,
                        cardColor,
                        textColor,
                        subTextColor,
                        kGreen,
                        kRed,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader("Allocation", subTextColor),
                      _buildAllocationChart(
                        totalEquityCurrent,
                        availableCash,
                        cardColor,
                        textColor,
                        subTextColor,
                        kBlue,
                        kGreen,
                      ),
                    ] else ...[
                      // F&O CONTENT
                      _buildSectionHeader(
                        "Positions (${fnoList.length})",
                        subTextColor,
                        trailing: "See All",
                      ),
                      fnoList.isEmpty
                          ? _buildEmptyState(
                              "No Active F&O Positions",
                              cardColor,
                              subTextColor,
                            )
                          : _buildHoldingsList(
                              fnoList,
                              currency,
                              cardColor,
                              textColor,
                              subTextColor,
                              kGreen,
                              kRed,
                            ),
                    ],

                    const SizedBox(height: 24),

                    // --- 4. RECENT ACTIVITY (FILTERED BY TAB) ---
                    _buildSectionHeader("Recent Activity", subTextColor),
                    _buildRecentTransactions(
                      currency,
                      cardColor,
                      textColor,
                      subTextColor,
                      kGreen,
                      kRed,
                      _selectedSegment, // PASSING SELECTION HERE
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

  // --- WIDGET HELPER METHODS ---

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
            fontSize: 10,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.layers_clear_outlined,
            size: 40,
            color: subTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: subTextColor)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color subTextColor, {
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF007AFF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
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
    if (equity <= 0 && cash <= 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "No assets to display",
            style: TextStyle(color: subTextColor),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 30,
                startDegreeOffset: -90,
                sections: [
                  if (equity > 0)
                    PieChartSectionData(
                      value: equity,
                      color: stockColor,
                      radius: 18,
                      showTitle: false,
                    ),
                  if (cash > 0)
                    PieChartSectionData(
                      value: cash,
                      color: cashColor,
                      radius: 18,
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
                  "Stocks",
                  equity,
                  stockColor,
                  textColor,
                  subTextColor,
                ),
                const SizedBox(height: 16),
                _buildLegendItem(
                  "Cash",
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
            Text(
              title,
              style: TextStyle(
                color: subTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              currency.format(value),
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Total Portfolio Value",
            style: TextStyle(color: subTextColor, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(totalValue),
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.w700,
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
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invested",
                      style: TextStyle(color: subTextColor, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(invested),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Cash",
                      style: TextStyle(color: subTextColor, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(cash),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Overall Returns",
                      style: TextStyle(color: subTextColor, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${overallPL >= 0 ? '+' : ''}${currency.format(overallPL)}",
                      style: TextStyle(
                        color: overallPL >= 0 ? kGreen : kRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    if (holdings.isEmpty) {
      return _buildEmptyState("No holdings found", cardColor, subTextColor);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
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
          color: subTextColor.withOpacity(0.2),
        ),
        itemBuilder: (context, index) {
          final stock = holdings[index];
          final double profitLoss = stock['currentVal'] - stock['investedVal'];
          final bool isProfit = profitLoss >= 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.show_chart,
                color: Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              stock['symbol'],
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            subtitle: Text(
              "${stock['quantity']} Qty • Avg ${currency.format(stock['avgBuyPrice'])}",
              style: TextStyle(color: subTextColor, fontSize: 10),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(stock['currentVal']),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                Text(
                  "${isProfit ? '+' : ''}${currency.format(profitLoss)}",
                  style: TextStyle(
                    color: isProfit ? kGreen : kRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- NEW PROFESSIONAL & FILTERED RECENT ACTIVITY ---
  Widget _buildRecentTransactions(
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 1. Filter Logic
        final allTransactions = snapshot.data ?? [];
        final filteredTransactions = allTransactions.where((txn) {
          // Logic to identify if a Transaction is F&O
          // Update this condition based on your exact data model
          bool isFnoTxn =
              txn.stockSymbol.endsWith("CE") || txn.stockSymbol.endsWith("PE");

          if (selectedSegment == 1) {
            return isFnoTxn; // Show F&O
          } else {
            return !isFnoTxn; // Show Stocks
          }
        }).toList();

        if (filteredTransactions.isEmpty) {
          return _buildEmptyState(
            selectedSegment == 0
                ? "No recent stock orders"
                : "No recent F&O trades",
            cardColor,
            subTextColor,
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            // Subtle shadow for pro feel
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
              indent: 16,
              endIndent: 16,
              color: subTextColor.withOpacity(0.15),
            ),
            itemBuilder: (context, index) {
              final txn = filteredTransactions[index];
              final bool isBuy = txn.transactionType.toUpperCase() == "BUY";
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
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Left: Symbol & Qty ---
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.stockSymbol,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "${txn.quantity} Qty",
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: subTextColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  txnTime,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // --- Right: Price & Tags ---
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currency.format(txn.totalAmount),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Product Tag (CNC vs NRML)
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
                                    selectedSegment == 0
                                        ? "CNC"
                                        : "NRML", // Mock tag
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: subTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // BUY/SELL Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isBuy ? kGreen : kRed).withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isBuy ? "BUY" : "SELL",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isBuy ? kGreen : kRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
