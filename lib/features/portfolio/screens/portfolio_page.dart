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
        final holdings = userProfile.stocks;
        final availableCash = userProfile.availableFunds;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<InstrumentProvider>(
            context,
            listen: false,
          ).fetchLiveDataForHoldings(holdings);
        });

        return Consumer<InstrumentProvider>(
          builder: (context, instrumentProvider, child) {
            double totalEquityValue = 0;
            double totalInvested = 0;
            double todaysPL = 0;
            final List<Map<String, dynamic>> calculatedHoldings = [];

            for (var holding in holdings) {
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

              totalEquityValue += currentVal;
              totalInvested += investedVal;
              todaysPL += (currentPrice - yesterdayClose) * holding.quantity;

              calculatedHoldings.add({
                'symbol': holding.stockSymbol,
                'quantity': holding.quantity,
                'avgBuyPrice': holding.transactionPrice,
                'currentPrice': currentPrice,
                'companyName': holding.stockName,
                'currentVal': currentVal,
                'investedVal': investedVal,
              });
            }

            double totalPortfolioValue = totalEquityValue + availableCash;
            double overallPL = totalEquityValue - totalInvested;
            double overallPLPercent = (totalInvested > 0)
                ? (overallPL / totalInvested) * 100
                : 0.0;

            return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                title: Text(
                  "Portfolio",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
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

                    _buildSectionHeader("Account", subTextColor),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          userProfile.name.isEmpty
                              ? "Trader"
                              : userProfile.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "BullXchange Pro",
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "PRO",
                            style: TextStyle(
                              color: kBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader("Overview", subTextColor),
                    _buildSummaryCard(
                      totalPortfolioValue,
                      todaysPL,
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

                    _buildSectionHeader("Allocation", subTextColor),
                    _buildAllocationChart(
                      totalEquityValue,
                      availableCash,
                      cardColor,
                      textColor,
                      subTextColor,
                      kBlue,
                      kGreen,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      "Holdings",
                      subTextColor,
                      trailing: "See All",
                    ),
                    _buildHoldingsList(
                      calculatedHoldings,
                      currency,
                      cardColor,
                      textColor,
                      subTextColor,
                      kGreen,
                      kRed,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader("Recent Activity", subTextColor),
                    _buildRecentTransactions(
                      currency,
                      cardColor,
                      textColor,
                      subTextColor,
                      kGreen,
                      kRed,
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

  // --- WIDGETS (Unchanged from previous reliable version) ---

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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF007AFF),
                fontSize: 13,
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              currency.format(value),
              style: TextStyle(
                color: textColor,
                fontSize: 15,
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
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(totalValue),
            style: TextStyle(
              color: textColor,
              fontSize: 34,
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
                    fontSize: 13,
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
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(invested),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(cash),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${overallPL >= 0 ? '+' : ''}${currency.format(overallPL)}",
                      style: TextStyle(
                        color: overallPL >= 0 ? kGreen : kRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "No holdings found",
            style: TextStyle(color: subTextColor),
          ),
        ),
      );
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
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              "${stock['quantity']} Qty • Avg ${currency.format(stock['avgBuyPrice'])}",
              style: TextStyle(color: subTextColor, fontSize: 12),
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
                    fontSize: 15,
                  ),
                ),
                Text(
                  "${isProfit ? '+' : ''}${currency.format(profitLoss)}",
                  style: TextStyle(
                    color: isProfit ? kGreen : kRed,
                    fontSize: 12,
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

  Widget _buildRecentTransactions(
    NumberFormat currency,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color kGreen,
    Color kRed,
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "No recent transactions",
                style: TextStyle(color: subTextColor),
              ),
            ),
          );
        }

        final transactions = snapshot.data!;

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
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            separatorBuilder: (ctx, idx) => Divider(
              height: 1,
              thickness: 0.5,
              indent: 60,
              color: subTextColor.withOpacity(0.2),
            ),
            itemBuilder: (context, index) {
              final txn = transactions[index];
              final bool isBuy = txn.transactionType == "BUY";
              final String txnTime = DateFormat(
                'd MMM',
              ).format(txn.transactionTime);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
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
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isBuy ? kGreen : kRed).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isBuy ? kGreen : kRed,
                    size: 18,
                  ),
                ),
                title: Text(
                  txn.stockSymbol,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "${isBuy ? 'Bought' : 'Sold'} • $txnTime",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currency.format(txn.totalAmount),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: subTextColor.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
