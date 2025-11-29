import 'package:bullxchange/features/stock_market/screens/buy_stock_page.dart';
import 'package:bullxchange/features/stock_market/screens/sell_stock_page.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:bullxchange/widgets/trade_action_buttons.dart';

class StockDetailPage extends StatefulWidget {
  final Instrument instrument;
  const StockDetailPage({super.key, required this.instrument});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  final UserService _userService = UserService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final UserService _bottomButtonUserService = UserService();

  void _toggleWatchlist() async {
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }
    try {
      await _userService.toggleWatchlistStock(uid!, widget.instrument.token);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    final netChange =
        (widget.instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
    final percentChange =
        (widget.instrument.liveData['percentChange'] as num?)?.toDouble() ??
        0.0;
    final changeColor = netChange >= 0
        ? const Color(0xFF1EAB58)
        : colorScheme.secondary;
    final priceParts = ltp.toStringAsFixed(2).split('.');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          widget.instrument.symbol.replaceAll('-EQ', ''),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: StreamBuilder<UserProfileDataModel?>(
                stream: (uid != null)
                    ? _userService.streamUserProfile(uid!)
                    : null,
                builder: (context, snapshot) {
                  bool isInWatchlist = false;
                  if (snapshot.hasData && snapshot.data != null) {
                    isInWatchlist = snapshot.data!.watchlist.contains(
                      widget.instrument.token,
                    );
                  }
                  return IconButton(
                    icon: Icon(
                      isInWatchlist
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isInWatchlist
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      size: 22,
                    ),
                    onPressed: _toggleWatchlist,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section (Card Style) ---
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildCompanyHeader(context, widget.instrument),
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 16),
                  _buildPriceDetails(
                    context,
                    priceParts,
                    netChange,
                    percentChange,
                    changeColor,
                  ),
                ],
              ),
            ),
            // --- Chart Section ---
            Container(
              height: 400, // Slightly reduced height
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: TradingViewChart(instrument: widget.instrument),
              ),
            ),
            const SizedBox(height: 20),
            // --- Statistics Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Market Statistics",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<InstrumentProvider>(
              builder: (context, prov, child) {
                final matched =
                    prov.getInstrumentByToken(widget.instrument.token) ??
                    widget.instrument;
                final live = matched.liveData;
                return _buildStatisticsCard(
                  context: context,
                  open: (live['open'] as num?)?.toDouble() ?? 0.0,
                  high: (live['high'] as num?)?.toDouble() ?? 0.0,
                  low: (live['low'] as num?)?.toDouble() ?? 0.0,
                  volume: (live['tradeVolume'] as num?)?.toInt() ?? 0,
                  avgPrice: (live['avgPrice'] as num?)?.toDouble() ?? 0.0,
                  upperCircuit:
                      (live['upperCircuit'] as num?)?.toDouble() ?? 0.0,
                  lowerCircuit:
                      (live['lowerCircuit'] as num?)?.toDouble() ?? 0.0,
                  fiftyTwoWeekHigh:
                      (live['52WeekHigh'] as num?)?.toDouble() ?? 0.0,
                  fiftyTwoWeekLow:
                      (live['52WeekLow'] as num?)?.toDouble() ?? 0.0,
                  marketCap: ltp * matched.outstandingShares,
                  avgVolume: matched.avgVolume.toDouble(),
                  outstandingShares: matched.outstandingShares,
                );
              },
            ),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TradeActionButtons(
              onSell: () async {
                HapticFeedback.lightImpact();
                if (uid == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please log in to sell stocks."),
                      ),
                    );
                  }
                  return;
                }
                final userProfile = await _bottomButtonUserService
                    .readUserProfile(uid!);
                if (userProfile == null || userProfile.stocks.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You do not own this stock."),
                      ),
                    );
                  }
                  return;
                }
                StockHoldingModel? holdingToSell;
                try {
                  final symbolToFind = widget.instrument.symbol.replaceAll(
                    '-EQ',
                    '',
                  );
                  holdingToSell = userProfile.stocks.firstWhere(
                    (holding) => holding.stockSymbol == symbolToFind,
                  );
                } catch (e) {
                  holdingToSell = null;
                }
                if (context.mounted) {
                  if (holdingToSell != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellStockPage(
                          instrument: widget.instrument,
                          userHolding: holdingToSell!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You do not own this stock."),
                      ),
                    );
                  }
                }
              },
              onBuy: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BuyStockPage(instrument: widget.instrument),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(BuildContext context, Instrument instrument) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: SmartLogo(instrument: instrument, radius: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instrument.symbol.replaceAll('-EQ', ''),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                instrument.name,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDetails(
    BuildContext context,
    List<String> priceParts,
    double netChange,
    double percentChange,
    Color changeColor,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Price",
              style: textTheme.labelMedium?.copyWith(
                color: textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "₹${priceParts[0]}",
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  ".${priceParts.length > 1 ? priceParts[1] : '00'}",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: changeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                percentChange >= 0 ? Icons.trending_up : Icons.trending_down,
                color: changeColor,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                "${netChange >= 0 ? '+' : ''}${netChange.toStringAsFixed(2)} (${percentChange.abs().toStringAsFixed(2)}%)",
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard({
    required BuildContext context,
    required double open,
    required double high,
    required double low,
    required int volume,
    required double avgPrice,
    required double upperCircuit,
    required double lowerCircuit,
    required double fiftyTwoWeekHigh,
    required double fiftyTwoWeekLow,
    required double marketCap,
    required double avgVolume,
    required double outstandingShares,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final volumeFormatter = NumberFormat.compact();
    final List<Map<String, String>> stats = [
      {"label": "Open", "value": "₹${open.toStringAsFixed(2)}"},
      {"label": "High", "value": "₹${high.toStringAsFixed(2)}"},
      {"label": "Low", "value": "₹${low.toStringAsFixed(2)}"},
      {"label": "Volume", "value": volumeFormatter.format(volume)},
      {"label": "Avg. Price", "value": "₹${avgPrice.toStringAsFixed(2)}"},
      {"label": "Upper Cir.", "value": "₹${upperCircuit.toStringAsFixed(2)}"},
      {"label": "Lower Cir.", "value": "₹${lowerCircuit.toStringAsFixed(2)}"},
      {"label": "52W High", "value": "₹${fiftyTwoWeekHigh.toStringAsFixed(2)}"},
      {"label": "52W Low", "value": "₹${fiftyTwoWeekLow.toStringAsFixed(2)}"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['label']!,
                  style: textTheme.bodySmall?.copyWith(
                    color: textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stat['value']!,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TradingViewChart extends StatefulWidget {
  final Instrument instrument;
  const TradingViewChart({super.key, required this.instrument});

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late final WebViewController _controller;
  String _currentAppliedTheme = "";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    String chartTheme = (brightness == Brightness.dark) ? "dark" : "light";
    String toolbarBg = (brightness == Brightness.dark) ? "#1E1E1E" : "#f1f3f6";

    if (_currentAppliedTheme != chartTheme) {
      _currentAppliedTheme = chartTheme;
      _controller.loadHtmlString(_buildTradingViewHtml(chartTheme, toolbarBg));
    }
  }

  String _buildTradingViewHtml(String chartTheme, String toolbarBg) {
    final sanitizedSymbol = widget.instrument.symbol.replaceAll('-EQ', '');
    final tradingViewSymbol = 'BSE:$sanitizedSymbol';

    return '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>TradingView Chart</title>
          <style> body { margin: 0; padding: 0; } </style>
        </head>
        <body>
          <div id="tradingview_chart_container" style="height: 100vh; width: 100vw;"></div>
          <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
          <script type="text/javascript">
            new TradingView.widget({
              "autosize": true,
              "symbol": "$tradingViewSymbol", 
              "interval": "D",
              "intervals": ["1", "5", "15", "30", "60", "D", "W", "M"],
              "timezone": "Asia/Kolkata",
              "theme": "$chartTheme", 
              "style": "1",
              "locale": "in",
              "toolbar_bg": "$toolbarBg",
              "enable_publishing": false,
              "withdateranges": true,
              "hide_side_toolbar": false,
              "allow_symbol_change": true,
              "details": true, 
              "hotlist": true,
              "calendar": true,
              "container_id": "tradingview_chart_container"
            });
          </script>
        </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
