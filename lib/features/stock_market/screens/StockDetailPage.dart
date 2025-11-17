// --- ⭐️ ADDED IMPORTS ---
import 'package:bullxchange/provider/theme_provider.dart';
// -------------------------

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
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- ⭐️ REMOVED HARDCODED COLORS ---
    // const Color primaryPink = ...
    // const Color primaryBlue = ...
    // const Color darkTextColor = ...
    // const Color lightGreyBg = ...

    final ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    final netChange =
        (widget.instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
    final percentChange =
        (widget.instrument.liveData['percentChange'] as num?)?.toDouble() ??
        0.0;

    // --- ⭐️ MODIFIED: Use theme's pink (secondary) color ---
    final changeColor = netChange >= 0
        ? const Color(0xFF1EAB58)
        : colorScheme.secondary;
    final priceParts = ltp.toStringAsFixed(2).split('.');

    return StreamBuilder<UserProfileDataModel?>(
      stream: (uid != null) ? _userService.streamUserProfile(uid!) : null,
      builder: (context, snapshot) {
        bool isInWatchlist = false;
        if (snapshot.hasData && snapshot.data != null) {
          isInWatchlist = snapshot.data!.watchlist.contains(
            widget.instrument.token,
          );
        }

        return Scaffold(
          // --- ⭐️ MODIFIED: Theme background color ---
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            // --- ⭐️ MODIFIED: Theme App Bar color ---
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: theme.appBarTheme.elevation,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  // --- ⭐️ MODIFIED: Theme surface color ---
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      // --- ⭐️ MODIFIED: Theme shadow color ---
                      color: theme.shadowColor.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    // --- ⭐️ MODIFIED: Theme icon color ---
                    color: colorScheme.onSurface,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              widget.instrument.symbol.replaceAll('-EQ', ''),
              // --- ⭐️ MODIFIED: Style ab AppTheme se aa raha hai ---
              style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  // --- ⭐️ MODIFIED: Theme surface color ---
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      // --- ⭐️ MODIFIED: Theme shadow color ---
                      color: theme.shadowColor.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isInWatchlist
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined,
                    // --- ⭐️ MODIFIED: Theme icon colors ---
                    color: isInWatchlist
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: _toggleWatchlist,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyHeader(
                    context, // ⭐️ Pass context
                    widget.instrument,
                    percentChange,
                    changeColor,
                  ),
                  const SizedBox(height: 10),
                  _buildPriceDetails(
                    context, // ⭐️ Pass context
                    priceParts,
                    netChange,
                    changeColor,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 420,
                    child: TradingViewChart(
                      instrument: widget.instrument,
                    ), // ⭐️ Yeh ab theme-aware hai
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Statistics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // --- ⭐️ MODIFIED: Theme text color ---
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer<InstrumentProvider>(
                    builder: (context, prov, child) {
                      final matched =
                          prov.getInstrumentByToken(widget.instrument.token) ??
                          widget.instrument;
                      final apiOpen =
                          (matched.liveData['open'] as num?)?.toDouble() ?? 0.0;
                      final apiHigh =
                          (matched.liveData['high'] as num?)?.toDouble() ?? 0.0;
                      final apiLow =
                          (matched.liveData['low'] as num?)?.toDouble() ?? 0.0;
                      final apiVolume =
                          (matched.liveData['tradeVolume'] as num?)?.toInt() ??
                          0;
                      final apiAvgPrice =
                          (matched.liveData['avgPrice'] as num?)?.toDouble() ??
                          0.0;
                      final apiUpperCircuit =
                          (matched.liveData['upperCircuit'] as num?)
                              ?.toDouble() ??
                          0.0;
                      final apiLowerCircuit =
                          (matched.liveData['lowerCircuit'] as num?)
                              ?.toDouble() ??
                          0.0;
                      final api52WkHigh =
                          (matched.liveData['52WeekHigh'] as num?)
                              ?.toDouble() ??
                          0.0;
                      final api52WkLow =
                          (matched.liveData['52WeekLow'] as num?)?.toDouble() ??
                          0.0;

                      final double outstandingShares =
                          matched.outstandingShares;
                      final int avgVolume = matched.avgVolume;
                      final double marketCap = ltp * outstandingShares;

                      return _buildStatisticsCard(
                        context: context, // ⭐️ Pass context
                        open: apiOpen,
                        high: apiHigh,
                        low: apiLow,
                        volume: apiVolume,
                        avgPrice: apiAvgPrice,
                        upperCircuit: apiUpperCircuit,
                        lowerCircuit: apiLowerCircuit,
                        fiftyTwoWeekHigh: api52WkHigh,
                        fiftyTwoWeekLow: api52WkLow,
                        marketCap: marketCap,
                        avgVolume: avgVolume.toDouble(),
                        outstandingShares: outstandingShares,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: SizedBox(
              height: 72.0,
              child: _buildBottomButtons(
                context, // ⭐️ Pass context
                ltp,
                widget.instrument,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Widget Builders (Refactored for Theme) ---

  Widget _buildCompanyHeader(
    BuildContext context, // ⭐️ Added context
    Instrument instrument,
    double percentChange,
    Color changeColor,
  ) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SmartLogo(instrument: instrument, radius: 0),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instrument.symbol.replaceAll('-EQ', ''),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                instrument.name,
                style: TextStyle(
                  fontSize: 14,
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  color: textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: changeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                percentChange >= 0
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                color: changeColor,
                size: 24,
              ),
              Text(
                "${percentChange.abs().toStringAsFixed(2)}%",
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDetails(
    BuildContext context, // ⭐️ Added context
    List<String> priceParts,
    double netChange,
    Color changeColor,
  ) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${priceParts[0]}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                ".${priceParts.length > 1 ? priceParts[1] : '00'}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 4),
                child: Text(
                  "${netChange >= 0 ? '+' : ''}${netChange.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard({
    required BuildContext context, // ⭐️ Added context
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
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final volumeFormatter = NumberFormat.decimalPattern('en_US');

    final List<Map<String, String>> stats = [
      {"label": "Open", "value": "₹${open.toStringAsFixed(2)}"},
      {"label": "High", "value": "₹${high.toStringAsFixed(2)}"},
      {"label": "Low", "value": "₹${low.toStringAsFixed(2)}"},
      {"label": "Volume", "value": volumeFormatter.format(volume)},
      {"label": "Avg. Price", "value": "₹${avgPrice.toStringAsFixed(2)}"},
      {
        "label": "Upper Circuit",
        "value": "₹${upperCircuit.toStringAsFixed(2)}",
      },
      {"label": "52W High", "value": "₹${fiftyTwoWeekHigh.toStringAsFixed(2)}"},
      {"label": "52W Low", "value": "₹${fiftyTwoWeekLow.toStringAsFixed(2)}"},
      {
        "label": "Lower Circuit",
        "value": "₹${lowerCircuit.toStringAsFixed(2)}",
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme surface color ---
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 8,
          mainAxisExtent: 65.0,
        ),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat['label']!,
                style: TextStyle(
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  color: textTheme.bodySmall?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stat['value']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    double ltp,
    Instrument instrument,
  ) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // --- ⭐️ MODIFIED: Theme nav bar color ---
      color: theme.bottomNavigationBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                // ... (Sell logic unchanged) ...
                final uid = FirebaseAuth.instance.currentUser?.uid;
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
                    .readUserProfile(uid);
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
                  final symbolToFind = instrument.symbol.replaceAll('-EQ', '');
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
                          instrument: instrument,
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
              style: ElevatedButton.styleFrom(
                // --- ⭐️ MODIFIED: Theme SELL color (Blue) ---
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Sell",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuyStockPage(instrument: instrument),
                ),
              ),
              style: ElevatedButton.styleFrom(
                // --- ⭐️ MODIFIED: Theme BUY color (Pink) ---
                backgroundColor: colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Buy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ✨ CHART WIDGET (Theme-Aware & Error Fixed) ---
class TradingViewChart extends StatefulWidget {
  final Instrument instrument;
  const TradingViewChart({super.key, required this.instrument});

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  // --- ⭐️ MODIFIED: Added flag ---
  late final WebViewController _controller;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    // ⭐️ InitState ko khaali rakha
  }

  // --- ⭐️⭐️ FIX: Logic ko initState se didChangeDependencies mein move kiya ⭐️⭐️ ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Controller ko sirf ek baar initialize karein
    if (!_isControllerInitialized) {
      final themeMode = Provider.of<ThemeNotifier>(
        context,
        listen: false,
      ).themeMode;
      // Fallback ke saath Brightness use kiya
      final brightness =
          MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;

      String chartTheme;
      String toolbarBg;

      if (themeMode == ThemeMode.dark) {
        chartTheme = "dark";
        toolbarBg = "#1E1E1E"; // (Dark Grey)
      } else if (themeMode == ThemeMode.light) {
        chartTheme = "light";
        toolbarBg = "#f1f3f6"; // (Light Grey)
      } else {
        // System
        chartTheme = (brightness == Brightness.dark) ? "dark" : "light";
        toolbarBg = (brightness == Brightness.dark) ? "#1E1E1E" : "#f1f3f6";
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadHtmlString(_buildTradingViewHtml(chartTheme, toolbarBg));

      // Flag set kiya taaki build method chale
      setState(() {
        _isControllerInitialized = true;
      });
    }
  }

  String _buildTradingViewHtml(String chartTheme, String toolbarBg) {
    // ... (Yeh function unchanged hai) ...
    final sanitizedSymbol = widget.instrument.symbol.replaceAll('-EQ', '');
    final exchange = widget.instrument.exchSeg == 'NSE' ? 'NSE' : 'BSE';
    final tradingViewSymbol = '$exchange:$sanitizedSymbol';

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
              "timezone": "Asia/Kolata",
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
    // --- ⭐️ MODIFIED: Jab tak controller ready na ho, loader dikhayein ---
    if (!_isControllerInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    return WebViewWidget(controller: _controller);
  }
}
