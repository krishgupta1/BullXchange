import 'package:bullxchange/features/stock_market/widgets/native_stock_chart.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChartToggleWidget extends StatefulWidget {
  final Instrument instrument;
  const ChartToggleWidget({super.key, required this.instrument});

  @override
  State<ChartToggleWidget> createState() => _ChartToggleWidgetState();
}

class _ChartToggleWidgetState extends State<ChartToggleWidget> {
  bool _useNativeChart = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Chart type toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Chart Type:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useNativeChart = true),
                          child: Container(
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: _useNativeChart 
                                  ? colorScheme.primary 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Native',
                                style: TextStyle(
                                  color: _useNativeChart 
                                      ? Colors.white 
                                      : colorScheme.onSurface.withAlpha(150),
                                  fontWeight: _useNativeChart 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useNativeChart = false),
                          child: Container(
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: !_useNativeChart 
                                  ? colorScheme.primary 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'TradingView',
                                style: TextStyle(
                                  color: !_useNativeChart 
                                      ? Colors.white 
                                      : colorScheme.onSurface.withAlpha(150),
                                  fontWeight: !_useNativeChart 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Chart display
        Expanded(
          child: _useNativeChart
              ? NativeStockChart(instrument: widget.instrument)
              : TradingViewChart(instrument: widget.instrument),
        ),
      ],
    );
  }
}

// Import TradingViewChart from stock_detail_page or move it here
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
    // Try NSE first, then BSE as fallback
    final tradingViewSymbol = 'NSE:$sanitizedSymbol';

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
