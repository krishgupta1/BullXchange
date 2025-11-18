import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaperTradingPortfolio extends StatefulWidget {
  const PaperTradingPortfolio({super.key});

  @override
  State<PaperTradingPortfolio> createState() => _PaperTradingPortfolioState();
}

class _PaperTradingPortfolioState extends State<PaperTradingPortfolio> {
  // --- THEME COLORS ---
  static const Color kGreen = Color(0xFF00D09C);
  static const Color kRed = Color(0xFFEB5B3C);
  static const Color kDarkBg = Color(0xFF121212);
  static const Color kLightBg = Color(0xFFF5F7F9);
  static const Color kDarkCard = Color(0xFF1E1E1E);
  static const Color kLightCard = Colors.white;

  // --- MOCK DATA (Equity Only) ---
  final double availableCash = 150000.00; // Cash Balance

  final List<Map<String, dynamic>> equityHoldings = [
    {
      "symbol": "RELIANCE",
      "companyName": "Reliance Industries",
      "quantity": 20,
      "avgBuyPrice": 2400.00,
      "currentPrice": 2550.00,
      "yesterdayClose": 2530.00,
    },
    {
      "symbol": "TATASTEEL",
      "companyName": "Tata Steel Ltd",
      "quantity": 100,
      "avgBuyPrice": 130.00,
      "currentPrice": 118.50, // Loss
      "yesterdayClose": 120.00,
    },
    {
      "symbol": "INFY",
      "companyName": "Infosys Ltd",
      "quantity": 50,
      "avgBuyPrice": 1400.00,
      "currentPrice": 1420.00,
      "yesterdayClose": 1410.00,
    },
  ];

  final List<Map<String, dynamic>> transactions = [
    {
      "type": "BUY",
      "name": "RELIANCE",
      "qty": 5,
      "price": 2540.00,
      "time": "10:30 AM",
    },
    {
      "type": "SELL",
      "name": "HDFCBANK",
      "qty": 10,
      "price": 1600.00,
      "time": "Yesterday",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Theme Detection
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBg : kLightBg;
    final cardColor = isDark ? kDarkCard : kLightCard;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey[400] : Colors.grey[600];
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // --- CALCULATIONS (Based on your Formulas) ---

    // 1. Total Equity Value (Sum of all holdingValues)
    // 4. Total Invested Amount (Sum of qty * avgBuyPrice)
    // 7. Today's Profit/Loss (Sum of (current - close) * qty)
    double totalEquityValue = 0;
    double totalInvested = 0;
    double todaysPL = 0;

    for (var stock in equityHoldings) {
      double holdingValue = stock['quantity'] * stock['currentPrice'];
      double investedVal = stock['quantity'] * stock['avgBuyPrice'];

      totalEquityValue += holdingValue;
      totalInvested += investedVal;

      todaysPL +=
          (stock['currentPrice'] - stock['yesterdayClose']) * stock['quantity'];
    }

    // 3. Total Portfolio Value = Total Equity + Cash
    double totalPortfolioValue = totalEquityValue + availableCash;

    // 5. Overall Profit/Loss
    // Note: Standard logic is (Equity Value - Invested).
    // If we use (Portfolio - Invested), it includes Cash as profit.
    // Based on "Paper Trading" context, I will calculate P/L strictly on INVESTMENT performance.
    double overallPL = totalEquityValue - totalInvested;

    // 6. Overall P/L %
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
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
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
            // --- TOP SUMMARY SECTION ---
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
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

                  // Today's P/L
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        todaysPL >= 0
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
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

                  // Invested vs Cash vs Overall PL
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
            ),

            // --- ASSET ALLOCATION (PIE CHART) ---
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
                            color: const Color(0xFF5367FF), // Equity Blue
                            radius: 25,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: availableCash,
                            color: kGreen, // Cash Green
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
                      _buildLegendDot(
                        "Stocks",
                        const Color(0xFF5367FF),
                        textColor,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendDot("Cash", kGreen, textColor),
                    ],
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),

            // --- HOLDINGS LIST HEADER ---
            Padding(
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
                      color: kGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- HOLDINGS LIST ---
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: equityHoldings.length,
              itemBuilder: (context, index) {
                final stock = equityHoldings[index];

                // Per Stock Calculations
                double currentVal = stock['quantity'] * stock['currentPrice'];
                double investedVal = stock['quantity'] * stock['avgBuyPrice'];
                double profitLoss = currentVal - investedVal;
                double plPercent = (profitLoss / investedVal) * 100;
                bool isProfit = profitLoss >= 0;

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
                      // Row 1: Symbol and Current Price
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

                      // Row 2: Details (Qty, Avg, Value, P/L)
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
                            currency.format(currentVal),
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
            ),

            // --- RECENT TRANSACTIONS ---
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
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                bool isBuy = txn['type'] == "BUY";
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isBuy ? kGreen : kRed).withOpacity(0.1),
                      child: Icon(
                        isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isBuy ? kGreen : kRed,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      txn['name'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      txn['time'],
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currency.format(txn['price']),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${txn['qty']} Qty",
                          style: TextStyle(color: subText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // --- BOTTOM ACTION BUTTONS ---
      bottomNavigationBar: Container(
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
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
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
      ),
    );
  }

  // --- HELPER WIDGETS ---

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
