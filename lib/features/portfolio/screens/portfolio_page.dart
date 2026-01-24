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
import 'package:bullxchange/models/option_holding_model.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';
import 'package:bullxchange/utils/responsive_helper.dart';

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

  void _updateFnoHoldingsLiveData(List<OptionHoldingModel> fnoHoldings) {
    final symbols = fnoHoldings.map((h) => h.contractSymbol).toList();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // For F&O holdings, find the instruments and fetch their live data
      final provider = context.read<InstrumentProvider>();
      final instruments = symbols.map((symbol) => provider.getInstrumentBySymbol(symbol)).where((instrument) => instrument != null).cast<Instrument>().toList();
      
      if (instruments.isNotEmpty) {
        provider.fetchLiveDataFor(instruments);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive helper
    ResponsiveHelper.init(context, BoxConstraints.tightFor(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
    ));
    
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
            style: TextStyle(
              color: textColor,
              fontSize: ResponsiveHelper.captionFontSize,
              fontWeight: FontWeight.w500,
            ),
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
                style: TextStyle(
                  color: textColor,
                  fontSize: ResponsiveHelper.captionFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final userProfile = snapshot.data!;
        final allHoldings = userProfile.stocks;
        final fnoHoldings = userProfile.optionHoldings; // F&O positions are stored separately
        final availableCash = userProfile.availableFunds;

        if (allHoldings.isNotEmpty) {
          _updateHoldingsLiveData(allHoldings);
        }
        
        // Also fetch live data for F&O holdings
        if (fnoHoldings.isNotEmpty) {
          _updateFnoHoldingsLiveData(fnoHoldings);
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

            // Process Stock Holdings (Equity)
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

              stockList.add(holdingData);
              totalEquityCurrent += currentVal;
              totalEquityInvested += investedVal;
            }

            // Process F&O Holdings (Options)
            for (var holding in fnoHoldings) {
              final instrument = instrumentProvider.getInstrumentBySymbol(
                holding.contractSymbol,
              );
              final double currentPrice =
                  (instrument?.liveData['ltp'] as num?)?.toDouble() ??
                  holding.averagePrice;

              // Handle both long and short positions correctly
              final double invested = holding.averagePrice * holding.quantity.abs();
              final double currentVal = currentPrice * holding.quantity.abs();
              
              double positionPnl;
              if (holding.quantity < 0) {
                // Short position: Profit when price goes down
                positionPnl = (holding.averagePrice - currentPrice) * holding.quantity.abs();
              } else {
                // Long position: Profit when price goes up
                positionPnl = currentVal - invested;
              }
              
              // For today's P&L, we don't have yesterday's close for options
              // This would need historical data to calculate properly
              double dayPL = 0; // TODO: Implement when historical data available
              todaysTotalPL += dayPL;

              final holdingData = {
                'symbol': holding.contractSymbol,
                'quantity': holding.quantity,
                'avgBuyPrice': holding.averagePrice,
                'currentPrice': currentPrice,
                'companyName': holding.symbol,
                'currentVal': currentVal,
                'investedVal': invested,
                'pnl': positionPnl, // Store individual P&L
              };

              fnoList.add(holdingData);
              totalFnoCurrent += currentVal;
              totalFnoInvested += invested;
            }

            // --- AGGREGATED TOTALS ---
            double totalPortfolioValue =
                availableCash + totalEquityCurrent + totalFnoCurrent;
            double totalInvested = totalEquityInvested + totalFnoInvested;
            double totalEquityPL = totalEquityCurrent - totalEquityInvested;
            
            // Calculate F&O P&L correctly by summing individual position P&L
            double totalFnoPL = fnoList.fold(0.0, (sum, holding) => sum + (holding['pnl'] ?? 0.0));
            
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
                    fontSize: ResponsiveHelper.appBarFontSize,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: ResponsiveHelper.verticalPadding * 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ResponsiveHelper.smallSpacing),

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

                    SizedBox(height: ResponsiveHelper.sectionSpacing),

                    // --- 2. SMOOTH TAB SWITCHER ---
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding),
                      padding: EdgeInsets.all(ResponsiveHelper.tinySpacing),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius * 0.6),
                        border: Border.all(
                          color: subTextColor.withValues(alpha: 0.1),
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

                    SizedBox(height: ResponsiveHelper.itemSpacing),

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
                      SizedBox(height: ResponsiveHelper.sectionSpacing),
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
        padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.smallSpacing),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius * 0.4),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : textColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.smallFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, Color cardColor, Color subTextColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding),
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding * 1.5),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.layers_clear_outlined,
            size: ResponsiveHelper.iconSize * 1.7,
            color: subTextColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: ResponsiveHelper.smallSpacing),
          Text(msg, style: TextStyle(color: subTextColor, fontSize: ResponsiveHelper.captionFontSize)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subTextColor) {
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveHelper.horizontalPadding * 1.25, 
        right: ResponsiveHelper.horizontalPadding * 1.25, 
        bottom: ResponsiveHelper.smallSpacing
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: subTextColor,
          fontSize: ResponsiveHelper.tinyFontSize,
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
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding),
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: ResponsiveHelper.cardBorderRadius * 0.75,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Total Portfolio Value",
            style: TextStyle(color: subTextColor, fontSize: ResponsiveHelper.captionFontSize),
          ),
          SizedBox(height: ResponsiveHelper.tinySpacing * 1.5),
          Text(
            currency.format(totalValue),
            style: TextStyle(
              color: textColor,
              fontSize: ResponsiveHelper.h1FontSize * 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: ResponsiveHelper.itemSpacing),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.smallSpacing * 1.5, 
              vertical: ResponsiveHelper.tinySpacing * 1.5
            ),
            decoration: BoxDecoration(
              color: (todaysPL >= 0 ? kGreen : kRed).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius * 0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  todaysPL >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: ResponsiveHelper.iconSize * 0.6,
                  color: todaysPL >= 0 ? kGreen : kRed,
                ),
                SizedBox(width: ResponsiveHelper.tinySpacing),
                Text(
                  "Today: ${currency.format(todaysPL.abs())}",
                  style: TextStyle(
                    color: todaysPL >= 0 ? kGreen : kRed,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.captionFontSize,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.sectionSpacing),

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
                    style: TextStyle(color: subTextColor, fontSize: ResponsiveHelper.tinyFontSize),
                  ),
                  SizedBox(height: ResponsiveHelper.tinySpacing),
                  Text(
                    "${overallPL >= 0 ? '+' : ''}${currency.format(overallPL)}",
                    style: TextStyle(
                      color: overallPL >= 0 ? kGreen : kRed,
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.captionFontSize,
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
        Text(label, style: TextStyle(color: subTextColor, fontSize: ResponsiveHelper.tinyFontSize)),
        SizedBox(height: ResponsiveHelper.tinySpacing),
        Text(
          currency.format(value),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.captionFontSize,
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
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: ResponsiveHelper.cardBorderRadius * 0.5,
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
          indent: ResponsiveHelper.avatarSize + ResponsiveHelper.smallSpacing,
          endIndent: ResponsiveHelper.horizontalPadding,
          color: subTextColor.withValues(alpha: 0.15),
        ),
        itemBuilder: (context, index) {
          final holding = holdings[index];
          final bool isFno = holding['symbol'].toString().endsWith("CE") || 
                            holding['symbol'].toString().endsWith("PE");
          
          // Use correct P&L calculation for F&O positions
          final double profitLoss = isFno 
              ? (holding['pnl'] ?? 0.0)  // Use pre-calculated P&L for F&O
              : (holding['currentVal'] - holding['investedVal']);  // Simple calculation for stocks
          final bool isProfit = profitLoss >= 0;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding,
              vertical: ResponsiveHelper.smallSpacing,
            ),
            child: Row(
              children: [
                // Leading icon/badge
                Container(
                  width: ResponsiveHelper.avatarSize * 0.8,
                  height: ResponsiveHelper.avatarSize * 0.8,
                  decoration: BoxDecoration(
                    color: isFno 
                        ? (holding['symbol'].toString().endsWith("CE") 
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1))
                        : Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius * 0.5),
                  ),
                  child: Center(
                    child: isFno
                        ? Text(
                            holding['symbol'].toString().endsWith("CE") ? "CE" : "PE",
                            style: TextStyle(
                              color: holding['symbol'].toString().endsWith("CE") 
                                  ? Colors.green 
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.tinyFontSize * 1.2,
                            ),
                          )
                        : Text(
                            holding['symbol'][0],
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.captionFontSize,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.smallSpacing),
                
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding['symbol'],
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.captionFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveHelper.tinySpacing),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${holding['quantity'].abs()} Qty • Avg ${currency.format(holding['avgBuyPrice'])}",
                              style: TextStyle(color: subTextColor, fontSize: ResponsiveHelper.captionFontSize),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFno) ...[
                            SizedBox(width: ResponsiveHelper.tinySpacing),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.tinySpacing, 
                                vertical: ResponsiveHelper.tinySpacing * 0.5
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(ResponsiveHelper.cardBorderRadius * 0.2),
                              ),
                              child: Text(
                                "F&O",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: ResponsiveHelper.tinyFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Trailing values
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(holding['currentVal']),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.captionFontSize,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.tinySpacing * 0.5),
                    Text(
                      "${isProfit ? '+' : ''}${currency.format(profitLoss)}",
                      style: TextStyle(
                        color: isProfit ? kGreen : kRed,
                        fontSize: ResponsiveHelper.captionFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                        color: Colors.black.withValues(alpha: 0.03),
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
                      color: subTextColor.withValues(alpha: 0.15),
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
                                  color: (isBuy ? kGreen : kRed).withValues(alpha: 0.1),
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
                                      color: subTextColor.withValues(alpha: 0.1),
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
