import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:bullxchange/widgets/custom_back_button.dart'; // Ensure this exists or remove
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// 1. MAIN PAGE (SCAFFOLD & TABS)
// ---------------------------------------------------------------------------
class OptionChainPage extends StatefulWidget {
  final String symbol;
  const OptionChainPage({super.key, required this.symbol});

  @override
  State<OptionChainPage> createState() => _OptionChainPageState();
}

class _OptionChainPageState extends State<OptionChainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Helper to map UI symbol to API symbol
  String _getApiSymbol(String uiSymbol) {
    final s = uiSymbol.toUpperCase().trim();
    if (s == "NIFTY MID SELECT" || s.contains("MIDCPNIFTY"))
      return "MIDCPNIFTY";
    if (s == "BANKEX") return "BANKEX";
    if (s == "SENSEX") return "SENSEX";
    if (s == "FINNIFTY") return "FINNIFTY";
    if (s == "BANKNIFTY" || s == "BANK NIFTY") return "BANKNIFTY";
    if (s == "NIFTY" || s == "NIFTY 50") return "NIFTY";
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final apiSymbol = _getApiSymbol(widget.symbol);

    return ChangeNotifierProvider(
      create: (_) => OptionChainProvider(symbol: apiSymbol),
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(), // Make sure this widget exists
          title: Text(
            widget.symbol,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Option Chain'),
              Tab(text: 'Overview'),
              Tab(text: 'Charts'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Option Chain Table
            const _OptionChainBody(),

            // Tab 2: Overview (Performance/Ranges)
            const OverviewTab(),

            // Tab 3: Charts (Placeholder)
            const Center(child: Text("Charts")),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. OPTION CHAIN BODY (THE TABLE)
// ---------------------------------------------------------------------------
class _OptionChainBody extends StatefulWidget {
  const _OptionChainBody();

  @override
  State<_OptionChainBody> createState() => _OptionChainBodyState();
}

class _OptionChainBodyState extends State<_OptionChainBody> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToAtm = false;
  final double _estimatedRowHeight = 58.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic v) {
    if (v == null) return "-";
    final p = double.tryParse(v.toString()) ?? 0.0;
    if (p == 0) return "-";
    return p.toStringAsFixed(2);
  }

  String _formatChange(dynamic v) {
    if (v == null) return "";
    final p = double.tryParse(v.toString()) ?? 0.0;
    if (p == 0) return "-";
    return "${p > 0 ? '+' : ''}${p.toStringAsFixed(2)}%";
  }

  String _formatOI(dynamic oiVal, dynamic lotSizeVal) {
    if (oiVal == null) return "-";
    double oi = double.tryParse(oiVal.toString()) ?? 0.0;
    if (oi == 0) return "-";

    int lotSize = int.tryParse(lotSizeVal.toString()) ?? 1;
    double lots = oi / lotSize;
    final f = NumberFormat("#,##0", "en_US");
    return f.format(lots);
  }

  Color _getChangeColor(dynamic v) {
    final p = double.tryParse(v.toString()) ?? 0.0;
    if (p > 0) return Colors.greenAccent;
    if (p < 0) return Colors.redAccent;
    return Colors.grey;
  }

  void _scrollToAtm(int atmIndex, double viewportHeight) {
    if (_hasScrolledToAtm) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double targetY = atmIndex * _estimatedRowHeight;
        final double offset =
            targetY - (viewportHeight / 2) + (_estimatedRowHeight / 2);
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
        _hasScrolledToAtm = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OptionChainProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : Colors.black87;

    if (provider.isLoading && provider.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!provider.isLoading && provider.rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "No data found for ${provider.symbol}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.fetchOptionChain(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final rows = provider.rows;
    final atmIndex = provider.atmIndex;
    final spotPrice = provider.underlyingLtp ?? 0.0;

    return Column(
      children: [
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: const [
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Call OI",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Call LTP",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Strike",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Put LTP",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Put OI",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (atmIndex != null)
                _scrollToAtm(atmIndex, constraints.maxHeight);

              return RefreshIndicator(
                onRefresh: () async {
                  _hasScrolledToAtm = false;
                  await provider.fetchOptionChain();
                },
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: rows.length,
                  separatorBuilder: (ctx, i) {
                    final currentStrike = rows[i].strikePrice;
                    if (i + 1 < rows.length) {
                      final nextStrike = rows[i + 1].strikePrice;
                      if (spotPrice >= currentStrike &&
                          spotPrice < nextStrike) {
                        return _buildSpotIndicator(spotPrice);
                      }
                    }
                    return Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey.withOpacity(0.2),
                    );
                  },
                  itemBuilder: (ctx, i) {
                    final row = rows[i];
                    final isAtm = atmIndex == i;
                    return Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          _cell(
                            top: _formatOI(
                              row.ce?['openInterest'],
                              row.ce?['lotSize'],
                            ),
                            sub: "",
                            txt: txtColor,
                          ),
                          _cell(
                            top: _formatPrice(row.ce?['lastPrice']),
                            sub: _formatChange(row.ce?['pChange']),
                            txt: txtColor,
                            subColor: _getChangeColor(row.ce?['pChange']),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                row.strikePrice.toStringAsFixed(0),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isAtm
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                          _cell(
                            top: _formatPrice(row.pe?['lastPrice']),
                            sub: _formatChange(row.pe?['pChange']),
                            txt: txtColor,
                            subColor: _getChangeColor(row.pe?['pChange']),
                          ),
                          _cell(
                            top: _formatOI(
                              row.pe?['openInterest'],
                              row.pe?['lotSize'],
                            ),
                            sub: "",
                            txt: txtColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpotIndicator(double price) {
    return Container(
      color: Colors.black,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Divider(color: Colors.white, thickness: 1, height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              price.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell({
    required String top,
    required String sub,
    required Color txt,
    Color? subColor,
  }) {
    return Expanded(
      flex: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            top,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: txt,
            ),
          ),
          if (sub.isNotEmpty && sub != "-")
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(sub, style: TextStyle(fontSize: 10, color: subColor)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. OVERVIEW TAB (NEW WIDGET FOR OVERVIEW)
// ---------------------------------------------------------------------------
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  String _formatNum(double? val) {
    if (val == null || val == 0) return "-";
    return NumberFormat("#,##0.00", "en_US").format(val);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OptionChainProvider>();
    final data = provider.overviewData;

    // Fallback loading check
    if (provider.isOverviewLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fallback Empty check
    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No Overview Data",
              style: TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: () => provider.fetchMarketOverview(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final isNegative = data.priceChange < 0;
    final color = isNegative ? Colors.redAccent : Colors.greenAccent;

    return RefreshIndicator(
      onRefresh: () async => await provider.fetchMarketOverview(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              provider.symbol,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatNum(data.currentPrice),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${isNegative ? '' : '+'}${_formatNum(data.priceChange)} (${data.percentChange.toStringAsFixed(2)}%)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance
            Row(
              children: [
                const Text(
                  "Performance",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(height: 20),

            // Today Range
            _RangeLabels(
              labelLow: "Today's Low",
              labelHigh: "Today's High",
              valLow: data.dayLow,
              valHigh: data.dayHigh,
            ),
            const SizedBox(height: 8),
            MarketRangeSlider(
              low: data.dayLow,
              high: data.dayHigh,
              current: data.currentPrice,
            ),
            const SizedBox(height: 24),

            // 52 Week Range
            _RangeLabels(
              labelLow: "52 Week Low",
              labelHigh: "52 Week High",
              valLow: data.yearLow,
              valHigh: data.yearHigh,
            ),
            const SizedBox(height: 8),
            MarketRangeSlider(
              low: data.yearLow,
              high: data.yearHigh,
              current: data.currentPrice,
            ),
            const SizedBox(height: 24),

            const Divider(color: Colors.grey, thickness: 0.2),
            const SizedBox(height: 16),

            // OHLC Grid
            Row(
              children: [
                Expanded(
                  child: _StatItem(label: "Open", value: _formatNum(data.open)),
                ),
                Expanded(
                  child: _StatItem(
                    label: "Prev. Close",
                    value: _formatNum(data.prevClose),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 0.2),

            // Lists
            _ListRow(title: "${provider.symbol} Companies"),
            _ListRow(title: "${provider.symbol} ETFs"),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. OVERVIEW HELPERS (Sliders, Labels)
// ---------------------------------------------------------------------------

class _RangeLabels extends StatelessWidget {
  final String labelLow, labelHigh;
  final double valLow, valHigh;
  const _RangeLabels({
    required this.labelLow,
    required this.labelHigh,
    required this.valLow,
    required this.valHigh,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat("#,##0.00", "en_US");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labelLow,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              valLow == 0 ? "-" : f.format(valLow),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              labelHigh,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              valHigh == 0 ? "-" : f.format(valHigh),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final bool alignEnd;
  const _StatItem({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  final String title;
  const _ListRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
        Divider(color: Colors.grey.withOpacity(0.2), height: 1),
      ],
    );
  }
}

class MarketRangeSlider extends StatelessWidget {
  final double low;
  final double high;
  final double current;

  const MarketRangeSlider({
    super.key,
    required this.low,
    required this.high,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    if (low == 0 || high == 0 || current == 0) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    double percentage = (current - low) / (high - low);
    percentage = percentage.clamp(0.0, 1.0);

    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double leftPos = (constraints.maxWidth * percentage) - 6;
          final double safeLeft = leftPos.clamp(0.0, constraints.maxWidth - 12);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Positioned(
                left: safeLeft,
                child: const Icon(
                  Icons.arrow_drop_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
