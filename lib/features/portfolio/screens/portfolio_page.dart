import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final UserService _userService = UserService();

  // 1. Declare the stream variable
  late Stream<List<TransactionModel>> _transactionStream;
  String _currentUid = "";

  // --- THEME COLORS ---
  static const Color kGreen = Color(0xFF00D09C);
  static const Color kRed = Color(0xFFEB5B3C);
  static const Color kDarkBg = Color(0xFF121212);
  static const Color kLightBg = Color(0xFFF5F7F9);
  static const Color kDarkCard = Color(0xFF1E1E1E);
  static const Color kLightCard = Colors.white;

  @override
  void initState() {
    super.initState();
    // 2. Initialize the stream ONCE here.
    // This prevents the loading spinner from appearing on every screen rebuild.
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    _currentUid = firebaseUser?.uid ?? "";

    if (_currentUid.isNotEmpty) {
      _transactionStream = _userService.streamRecentTransactions(_currentUid);
    } else {
      _transactionStream = Stream.value([]); // Empty stream if not logged in
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Detection
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBg : kLightBg;
    final cardColor = isDark ? kDarkCard : kLightCard;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey[400] : Colors.grey[600];
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (_currentUid.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: Text("Please login to view portfolio")),
      );
    }

    return StreamBuilder<UserProfileDataModel?>(
      stream: _userService.streamUserProfile(_currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Text(
                "Profile Not Found",
                style: TextStyle(color: textColor),
              ),
            ),
          );
        }

        final UserProfileDataModel userProfile = snapshot.data!;
        final List<StockHoldingModel> holdings = userProfile.stocks;
        final double availableCash = userProfile.availableFunds;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<InstrumentProvider>(
            context,
            listen: false,
          ).fetchLiveDataForHoldings(holdings);
        });

        return Consumer<InstrumentProvider>(
          builder: (context, instrumentProvider, child) {
            // --- CALCULATIONS ---
            double totalEquityValue = 0;
            double totalInvested = 0;
            double todaysPL = 0;
            final List<Map<String, dynamic>> calculatedHoldings = [];

            for (var holding in holdings) {
              final Instrument? instrument = instrumentProvider
                  .getInstrumentBySymbol(holding.stockSymbol);
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
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: bgColor,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  "Portfolio",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.analytics_outlined, color: textColor),
                    onPressed: () {},
                  ),
                ],
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserDetail(
                      userProfile.name,
                      textColor,
                      subText,
                      cardColor,
                    ),
                    _buildSummaryCard(
                      totalPortfolioValue,
                      todaysPL,
                      totalInvested,
                      availableCash,
                      overallPL,
                      overallPLPercent,
                      cardColor,
                      subText,
                      textColor,
                      currency,
                    ),
                    _buildAllocationChart(
                      totalEquityValue,
                      availableCash,
                      textColor,
                      subText,
                    ),
                    _buildHoldingsHeader(textColor, kGreen),
                    _buildHoldingsList(
                      calculatedHoldings,
                      currency,
                      cardColor,
                      subText,
                      textColor,
                    ),

                    // 3. Pass the Initialized Stream to the widget
                    _buildRecentTransactions(
                      _currentUid,
                      currency,
                      cardColor,
                      subText,
                      textColor,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomBar(
                textColor,
                cardColor,
                subText,
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper Widgets (Same as before) ---

  Widget _buildRecentTransactions(
    String uid,
    NumberFormat currency,
    Color cardColor,
    Color? subText,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            "Recent Transactions",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StreamBuilder<List<TransactionModel>>(
          stream: _userService.streamRecentTransactions(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(color: kGreen)),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "Error loading transactions.",
                    style: TextStyle(color: subText),
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "No recent transactions found.",
                    style: TextStyle(color: subText),
                  ),
                ),
              );
            }

            final transactions = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                bool isBuy = txn.transactionType == "BUY";

                final String txnTime = DateFormat(
                  'h:mm a, d MMM',
                ).format(txn.transactionTime);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    // --- ⭐️ NEW: NAVIGATE ON TAP ---
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsPage(
                            transaction: txn,
                            // Pass the ID safely (txn.id might be null initially)
                            transactionId: txn.id ?? "Unknown ID",
                          ),
                        ),
                      );
                    },

                    // --------------------------------
                    leading: CircleAvatar(
                      backgroundColor: (isBuy ? kGreen : kRed).withOpacity(0.1),
                      child: Icon(
                        isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isBuy ? kGreen : kRed,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      txn.stockSymbol,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      txnTime,
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currency.format(txn.totalAmount),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${txn.quantity} Qty",
                          style: TextStyle(color: subText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ... (Copy _buildUserDetail, _buildSummaryCard, _buildAllocationChart, _buildHoldingsHeader, _buildHoldingsList, _buildBottomBar, _buildDataCell, _buildLegendDot, _buildSummaryColumn from previous response)

  // For brevity, assuming helper widgets are below:
  Widget _buildUserDetail(
    String userName,
    Color textColor,
    Color? subText,
    Color cardColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF5367FF),
              radius: 20,
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? "Trader" : userName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "BullXchange Portfolio",
                  style: TextStyle(
                    color: subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF5367FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Color(0xFF5367FF), size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Diamond Trader",
                    style: TextStyle(
                      color: Color(0xFF5367FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    double totalPortfolioValue,
    double todaysPL,
    double totalInvested,
    double availableCash,
    double overallPL,
    double overallPLPercent,
    Color cardColor,
    Color? subText,
    Color textColor,
    NumberFormat currency,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Total Portfolio Value",
            style: TextStyle(
              color: subText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            currency.format(totalPortfolioValue),
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                todaysPL >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: todaysPL >= 0 ? kGreen : kRed,
              ),
              Text(
                "Today's P/L: ${currency.format(todaysPL)}",
                style: TextStyle(
                  color: todaysPL >= 0 ? kGreen : kRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: subText?.withOpacity(0.1)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryColumn(
                "Invested",
                currency.format(totalInvested),
                textColor,
                subText,
              ),
              _buildSummaryColumn(
                "Cash",
                currency.format(availableCash),
                textColor,
                subText,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Overall P/L",
                    style: TextStyle(color: subText, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${overallPL >= 0 ? '+' : ''}${currency.format(overallPL)}",
                    style: TextStyle(
                      color: overallPL >= 0 ? kGreen : kRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "(${overallPLPercent.toStringAsFixed(2)}%)",
                    style: TextStyle(
                      color: overallPL >= 0 ? kGreen : kRed,
                      fontSize: 11,
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

  Widget _buildAllocationChart(
    double totalEquityValue,
    double availableCash,
    Color textColor,
    Color? subText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            "Asset Allocation",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(
                        value: totalEquityValue,
                        color: const Color(0xFF5367FF),
                        radius: 25,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: availableCash,
                        color: kGreen,
                        radius: 25,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendDot("Stocks", const Color(0xFF5367FF), textColor),
                  const SizedBox(height: 8),
                  _buildLegendDot("Cash", kGreen, textColor),
                ],
              ),
              const SizedBox(width: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingsHeader(Color textColor, Color actionColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Holdings",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "See All",
            style: TextStyle(
              color: actionColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsList(
    List<Map<String, dynamic>> calculatedHoldings,
    NumberFormat currency,
    Color cardColor,
    Color? subText,
    Color textColor,
  ) {
    if (calculatedHoldings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text("No holdings yet.", style: TextStyle(color: subText)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: calculatedHoldings.length,
      itemBuilder: (context, index) {
        final stock = calculatedHoldings[index];
        final double profitLoss = stock['currentVal'] - stock['investedVal'];
        final double investedVal = stock['investedVal'];
        final double plPercent = (investedVal > 0)
            ? (profitLoss / investedVal) * 100
            : 0.0;
        final bool isProfit = profitLoss >= 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: subText!.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock['symbol'],
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        stock['companyName'],
                        style: TextStyle(color: subText, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(stock['currentPrice']),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "LTP",
                        style: TextStyle(color: subText, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: subText.withOpacity(0.1), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataCell(
                    "Qty",
                    "${stock['quantity']}",
                    subText,
                    textColor,
                  ),
                  _buildDataCell(
                    "Avg",
                    currency.format(stock['avgBuyPrice']),
                    subText,
                    textColor,
                  ),
                  _buildDataCell(
                    "Value",
                    currency.format(stock['currentVal']),
                    subText,
                    textColor,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "P/L",
                        style: TextStyle(color: subText, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${isProfit ? '+' : ''}${currency.format(profitLoss)}",
                        style: TextStyle(
                          color: isProfit ? kGreen : kRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "${plPercent.toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: isProfit ? kGreen : kRed,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(Color textColor, Color cardColor, Color? subText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: subText!.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: textColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Watchlist",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Sell",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Buy",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(
    String label,
    String value,
    Color textColor,
    Color? subText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: subText, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDataCell(
    String label,
    String value,
    Color? subText,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: subText, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(String text, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
