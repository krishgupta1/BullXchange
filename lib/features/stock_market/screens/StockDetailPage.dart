import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/provider/instrument_provider.dart';

class StockDetailPage extends StatelessWidget {
  final Instrument instrument;
  const StockDetailPage({super.key, required this.instrument});

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFF61C7A);
    const Color primaryBlue = Color(0xFF3500D4);
    const Color darkTextColor = Color(0xFF03314B);
    const Color lightGreyBg = Color(0xFFF5F5F5);

    // --- Dynamic Data Extraction ---
    final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    final netChange =
        (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
    final percentChange =
        (instrument.liveData['percentChange'] as num?)?.toDouble() ?? 0.0;
    final open = (instrument.liveData['open'] as num?)?.toDouble() ?? 0.0;
    final high = (instrument.liveData['high'] as num?)?.toDouble() ?? 0.0;
    final low = (instrument.liveData['low'] as num?)?.toDouble() ?? 0.0;
    final volume =
        (instrument.liveData['totalTradedVolume'] as num?)?.toInt() ?? 0;

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
          instrument.symbol.replaceAll('-EQ', ''),
          style: const TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                    TradingViewChart(symbol: instrument.symbol),
                    const SizedBox(height: 30),
                    const Text(
                      "Statistics",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkTextColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Read the provider-populated live data so the card updates when provider refreshes.
                    Consumer<InstrumentProvider>(
                      builder: (context, prov, child) {
                        final matched =
                            prov.getInstrumentByToken(instrument.token) ??
                            instrument;

                        final apiOpen =
                            (matched.liveData['open'] as num?)?.toDouble() ??
                            open;
                        final apiHigh =
                            (matched.liveData['high'] as num?)?.toDouble() ??
                            high;
                        final apiLow =
                            (matched.liveData['low'] as num?)?.toDouble() ??
                            low;
                        final apiVolume =
                            (matched.liveData['totalTradedVolume'] as num?)
                                ?.toInt() ??
                            (matched.liveData['volume'] as num?)?.toInt() ??
                            volume;

                        final apiAvgVolume =
                            (matched.liveData['avgVolume'] as num?)?.toInt();
                        final apiMarketCap =
                            (matched.liveData['marketCap'] as num?)?.toDouble();

                        return _buildStatisticsCard(
                          apiOpen,
                          apiHigh,
                          apiLow,
                          apiVolume,
                          apiAvgVolume,
                          apiMarketCap,
                          lightGreyBg,
                          darkTextColor,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 88.0,
          child: _buildBottomButtons(context, primaryPink, primaryBlue),
        ),
      ),
    );
  }

  String _formatMarketCap(double value) {
    try {
      final fmt = NumberFormat.compact(locale: 'en_US');
      return fmt.format(value);
    } catch (_) {
      if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
      if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
      if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
      return value.toStringAsFixed(0);
    }
  }

  // --- UI Component Builders ---
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
                instrument.symbol.replaceAll('-EQ', ''),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              Text(
                instrument.name,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                  fontSize: 16,
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
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              Text(
                ".${priceParts.length > 1 ? priceParts[1] : '00'}",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 4),
                child: Text(
                  "${netChange >= 0 ? '+' : ''}${netChange.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 20,
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

  // Time range selector removed per request.

  Widget _buildStatisticsCard(
    double open,
    double high,
    double low,
    int volume,
    int? avgVolume,
    double? marketCap,
    Color lightGreyBg,
    Color darkTextColor,
  ) {
    // Format the volume number with commas
    final volumeFormatter = NumberFormat.decimalPattern('en_US');
    String avgVolText = 'N/A';
    if (avgVolume != null) avgVolText = volumeFormatter.format(avgVolume);

    String marketCapText = 'N/A';
    if (marketCap != null) marketCapText = _formatMarketCap(marketCap);

    final List<Map<String, String>> stats = [
      {"label": "Open", "value": "₹${open.toStringAsFixed(2)}"},
      {"label": "High", "value": "₹${high.toStringAsFixed(2)}"},
      {"label": "Low", "value": "₹${low.toStringAsFixed(2)}"},
      {"label": "Volume", "value": volumeFormatter.format(volume)},
      {"label": "Avg. Volume", "value": avgVolText},
      {"label": "Market Cap", "value": marketCapText},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGreyBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 60.0,
        ),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat['label']!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                stat['value']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: darkTextColor,
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
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: buyColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: sellColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
    final sanitizedSymbol = widget.symbol.replaceAll('-EQ', '');

    final String tradingViewUrl =
        '''
      https://s.tradingview.com/widgetembed/?frameElementId=tradingview_7a905&symbol=BSE%3A$sanitizedSymbol&interval=D&hidesidetoolbar=1&symboledit=1&saveimage=1&toolbarbg=f1f3f6&studies=[]&theme=light&style=1&timezone=Etc%2FUTC&studies_overrides=%7B%7D&overrides=%7B%7D&enabled_features=[]&disabled_features=[]&locale=en&utm_source=www.tradingview.com&utm_medium=widget_new&utm_campaign=chart&utm_term=BSE%3A$sanitizedSymbol
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(tradingViewUrl.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 350, child: WebViewWidget(controller: _controller));
  }
}
