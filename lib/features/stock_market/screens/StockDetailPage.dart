import 'package:bullxchange/features/stock_market/screens/buy_stock_page.dart';
import 'package:bullxchange/features/stock_market/screens/sell_stock_page.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
// restored: removed company_name helper import to display original symbol/name

class StockDetailPage extends StatelessWidget {
  final Instrument instrument;
  const StockDetailPage({super.key, required this.instrument});

  // Instantiate the service for use in the bottom buttons

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFF61C7A);
    const Color primaryBlue = Color(0xFF3500D4);
    const Color darkTextColor = Color(0xFF03314B);
    const Color lightGreyBg = Color(0xFFF5F5F5);

    final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    final netChange =
        (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
    final percentChange =
        (instrument.liveData['percentChange'] as num?)?.toDouble() ?? 0.0;
    final changeColor = netChange >= 0 ? const Color(0xFF1EAB58) : primaryPink;
    final priceParts = ltp.toStringAsFixed(2).split('.');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          instrument.symbol.replaceAll('-EQ', ''), // restored: show symbol
          style: const TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      // --- 2. BODY USES A SINGLE SCROLL VIEW ---
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyHeader(
                instrument,
                percentChange,
                changeColor,
                darkTextColor,
              ),
              const SizedBox(height: 10),
              _buildPriceDetails(
                priceParts,
                netChange,
                changeColor,
                darkTextColor,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 420, // Height for the chart
                child: TradingViewChart(symbol: instrument.symbol),
              ),
              const SizedBox(height: 20),
              const Text(
                "Statistics",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Consumer<InstrumentProvider>(
                builder: (context, prov, child) {
                  final matched =
                      prov.getInstrumentByToken(instrument.token) ?? instrument;
                  final apiOpen =
                      (matched.liveData['open'] as num?)?.toDouble() ?? 0.0;
                  final apiHigh =
                      (matched.liveData['high'] as num?)?.toDouble() ?? 0.0;
                  final apiLow =
                      (matched.liveData['low'] as num?)?.toDouble() ?? 0.0;
                  final apiVolume =
                      (matched.liveData['tradeVolume'] as num?)?.toInt() ?? 0;
                  final apiAvgPrice =
                      (matched.liveData['avgPrice'] as num?)?.toDouble() ?? 0.0;
                  final apiUpperCircuit =
                      (matched.liveData['upperCircuit'] as num?)?.toDouble() ??
                      0.0;
                  final apiLowerCircuit =
                      (matched.liveData['lowerCircuit'] as num?)?.toDouble() ??
                      0.0;
                  final api52WkHigh =
                      (matched.liveData['52WeekHigh'] as num?)?.toDouble() ??
                      0.0;
                  final api52WkLow =
                      (matched.liveData['52WeekLow'] as num?)?.toDouble() ??
                      0.0;

                  // --- NEW VALUES ---
                  final double outstandingShares = matched.outstandingShares;
                  final int avgVolume = matched.avgVolume;
                  final double marketCap = ltp * outstandingShares;

                  return _buildStatisticsCard(
                    open: apiOpen,
                    high: apiHigh,
                    low: apiLow,
                    volume: apiVolume, // This is today's tradeVolume
                    avgPrice: apiAvgPrice,
                    upperCircuit: apiUpperCircuit,
                    lowerCircuit: apiLowerCircuit,
                    fiftyTwoWeekHigh: api52WkHigh,
                    fiftyTwoWeekLow: api52WkLow,
                    // --- PASSING NEW VALUES ---
                    marketCap: marketCap,
                    avgVolume: avgVolume.toDouble(), // This is the 30-day avg
                    outstandingShares: outstandingShares,
                    // ---
                    lightGreyBg: lightGreyBg,
                    darkTextColor: darkTextColor,
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
          child: _buildBottomButtons(context, primaryPink, primaryBlue, ltp),
        ),
      ),
    );
  }

  // --- Widget Builders (Updated to include ltp and service) ---

  Widget _buildCompanyHeader(
    Instrument instrument,
    double percentChange,
    Color changeColor,
    Color darkTextColor,
  ) {
    return Row(
      children: [
        SmartLogo(instrument: instrument),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instrument.symbol.replaceAll(
                  '-EQ',
                  '',
                ), // restored: symbol bold
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                instrument.name, // restored: faded short name below symbol
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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
    List<String> priceParts,
    double netChange,
    Color changeColor,
    Color darkTextColor,
  ) {
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
                  color: darkTextColor,
                ),
              ),
              Text(
                ".${priceParts.length > 1 ? priceParts[1] : '00'}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
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
    required double open,
    required double high,
    required double low,
    required int volume, // This is live tradeVolume
    required double avgPrice,
    required double upperCircuit,
    required double lowerCircuit,
    required double fiftyTwoWeekHigh,
    required double fiftyTwoWeekLow,
    // --- NEW PARAMETERS ---
    required double marketCap,
    required double avgVolume, // This is the 30-day avg
    required double outstandingShares,
    // ---
    required Color lightGreyBg,
    required Color darkTextColor,
  }) {
    final volumeFormatter = NumberFormat.decimalPattern('en_US');

    // --- UPDATED STATS LIST ---
    final List<Map<String, String>> stats = [
      {"label": "Open", "value": "₹${open.toStringAsFixed(2)}"},
      {"label": "High", "value": "₹${high.toStringAsFixed(2)}"},
      {"label": "Low", "value": "₹${low.toStringAsFixed(2)}"},
      {
        "label": "Volume",
        "value": volumeFormatter.format(volume),
      }, // Live Volume
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
    // --- END UPDATED STATS LIST ---

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: lightGreyBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length, // Now 12 items
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 8,
          mainAxisExtent: 62.0,
        ),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat['label']!,
                style: const TextStyle(
                  color: Colors.grey,
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
                    color: darkTextColor,
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
    Color buyColor,
    Color sellColor,
    double ltp, // Passed current Live Price
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          // --- BUY BUTTON WITH FIREBASE LOGIC ---
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuyStockPage(instrument: instrument),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buyColor, // Use buyColor
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Buy", // Text is "Buy"
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 15), // Added spacer
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                // 1. Get the current user's ID
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) {
                  // Handle case where user is not logged in
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please log in to sell stocks."),
                      ),
                    );
                  }
                  return;
                }

                // 2. Fetch the user's profile which contains their stock holdings
                // NOTE: You'll need an instance of UserService in your StockDetailPage class
                final userService = UserService();
                final userProfile = await userService.readUserProfile(uid);

                if (userProfile == null || userProfile.stocks.isEmpty) {
                  // Handle case where user has no holdings
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You do not own this stock."),
                      ),
                    );
                  }
                  return;
                }

                // 3. Find the specific stock holding that matches the current instrument
                StockHoldingModel? holdingToSell;
                try {
                  final symbolToFind = instrument.symbol.replaceAll('-EQ', '');
                  holdingToSell = userProfile.stocks.firstWhere(
                    (holding) => holding.stockSymbol == symbolToFind,
                  );
                } catch (e) {
                  // This catches the error if .firstWhere finds no matching element
                  holdingToSell = null;
                }

                // 4. Navigate to the SellStockPage if the holding was found
                if (context.mounted) {
                  if (holdingToSell != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellStockPage(
                          instrument: instrument,
                          userHolding:
                              holdingToSell!, // Pass the found holding here
                        ),
                      ),
                    );
                  } else {
                    // Handle case where the user owns other stocks, but not this one
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You do not own this stock."),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: sellColor, // Use sellColor
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
        ],
      ),
    );
  }
}

// --- Full-Featured TradingView Chart Widget ---
class TradingViewChart extends StatefulWidget {
  final String symbol;

  const TradingViewChart({super.key, required this.symbol});

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(_buildTradingViewHtml());
  }

  String _buildTradingViewHtml() {
    final sanitizedSymbol = widget.symbol.replaceAll('-EQ', '');
    // Hardcoded to BSE for better compatibility with free widget
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
              // --- UPDATED: All standard intervals ---
              "intervals": ["1", "5", "15", "30", "60", "D", "W", "M"],
              "timezone": "Asia/Kolata",
              "theme": "light",
              "style": "1",
              "locale": "in",
              "toolbar_bg": "#f1f3f6",
              "enable_publishing": false,
              "withdateranges": true,
              "hide_side_toolbar": false,
              "allow_symbol_change": true,
              "details": true, // This will show OHLC on hover
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
    // --- 3. GESTURE RECOGNIZERS REMOVED ---
    // This gives the WebView gesture priority, making its UI clickable.
    // The trade-off is you cannot scroll the page by dragging on the chart.
    return WebViewWidget(
      controller: _controller,
      // gestureRecognizers: { ... } - This is now removed.
    );
  }
}
