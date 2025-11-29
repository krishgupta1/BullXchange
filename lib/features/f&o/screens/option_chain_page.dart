import 'dart:async';
import 'package:bullxchange/features/f&o/screens/buy_option_page.dart';
import 'package:bullxchange/features/f&o/screens/sell_option_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

  String _getApiSymbol(String uiSymbol) {
    final s = uiSymbol.toUpperCase().trim();
    if (s == "NIFTY MID SELECT" || s.contains("MIDCPNIFTY")) {
      return "MIDCPNIFTY";
    }
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            widget.symbol,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
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
            const _OptionChainBody(),
            const OverviewTab(),
            const Center(
              child: Text("Charts", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChainBody extends StatefulWidget {
  const _OptionChainBody();
  @override
  State<_OptionChainBody> createState() => _OptionChainBodyState();
}

class _OptionChainBodyState extends State<_OptionChainBody>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToAtm = false;
  final double _estimatedRowHeight = 58.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchData();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _stopAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 100), (_) => _fetchData());
  }

  void _stopAutoRefresh() => _timer?.cancel();

  Future<void> _fetchData() async {
    if (mounted) context.read<OptionChainProvider>().fetchOptionChain();
  }

  // --- FORMATTING HELPERS ---
  String _fmtP(dynamic v) => (double.tryParse(v?.toString() ?? "0") ?? 0) == 0
      ? "-"
      : (double.tryParse(v?.toString() ?? "0") ?? 0).toStringAsFixed(2);
  String _fmtC(dynamic v) {
    final d = double.tryParse(v?.toString() ?? "0") ?? 0;
    return d == 0 ? "-" : "${d > 0 ? '+' : ''}${d.toStringAsFixed(2)}%";
  }

  String _formatOI(dynamic oiVal, dynamic lotSizeVal) {
    if (oiVal == null) return "-";
    double oi = double.tryParse(oiVal.toString()) ?? 0.0;
    if (oi == 0) return "-";
    int lotSize = int.tryParse(lotSizeVal?.toString() ?? "1") ?? 1;
    double lots = oi / lotSize;
    return NumberFormat("#,##0", "en_US").format(lots);
  }

  Color _col(dynamic v) {
    final d = double.tryParse(v?.toString() ?? "0") ?? 0.0;
    return d > 0
        ? Colors.greenAccent
        : (d < 0 ? Colors.redAccent : Colors.grey);
  }

  void _scrollToAtm(int idx, double h) {
    if (_hasScrolledToAtm) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          (idx * _estimatedRowHeight) - (h / 2) + (_estimatedRowHeight / 2),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
        _hasScrolledToAtm = true;
      }
    });
  }

  void _onOptionTap(BuildContext context, dynamic row, bool isCall) {
    final provider = context.read<OptionChainProvider>();
    final Map<String, dynamic>? data = isCall ? row.ce : row.pe;
    if (data == null ||
        (double.tryParse(data['lastPrice']?.toString() ?? "0") ?? 0) == 0) {
      return;
    }

    final double ltp = double.tryParse(data['lastPrice'].toString()) ?? 0.0;
    final instrument = Instrument(
      token: "",
      symbol: provider.symbol,
      name: provider.symbol,
      exchSeg: "F&O",
      expiry: row.expiryDate,
      strike: row.strikePrice.toString(),
      instrumentType: "OPTIDX",
      lotSize: data['lotSize']?.toString() ?? "25",
      outstandingShares: 0,
      avgVolume: 0,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildBottomSheet(
        ctx,
        context,
        provider.symbol,
        row.strikePrice,
        isCall ? "CE" : "PE",
        ltp,
        instrument,
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext ctx,
    BuildContext context,
    String sym,
    double strike,
    String type,
    double ltp,
    Instrument inst,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 250,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$sym $strike $type",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹$ltp",
                style: TextStyle(
                  color: type == "CE" ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuyOptionPage(
                            instrument: inst,
                            symbol: sym,
                            optionType: type,
                            strikePrice: strike,
                            ltp: ltp,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "BUY",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellOptionPage(
                            instrument: inst,
                            symbol: sym,
                            optionType: type,
                            strikePrice: strike,
                            ltp: ltp,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "SELL",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExpiryPicker(BuildContext context, OptionChainProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Expiry",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.expiryDates.length,
                itemBuilder: (ctx, i) {
                  final date = provider.expiryDates[i];
                  final isSel = date == provider.selectedExpiry;
                  return ListTile(
                    title: Text(
                      date,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSel ? Colors.blueAccent : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      _hasScrolledToAtm = false;
                      provider.selectExpiry(date);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. HEADER (Call | Expiry Dropdown | Put)
        Consumer<OptionChainProvider>(
          builder: (context, provider, _) {
            final expiryText = provider.selectedExpiry.isEmpty
                ? "Current"
                : provider.selectedExpiry;
            return Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Call price",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  GestureDetector(
                    onTap: () => _showExpiryPicker(context, provider),
                    child: Row(
                      children: [
                        Text(
                          expiryText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "Put price",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            );
          },
        ),

        // 2. COLUMNS HEADER
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "OI",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "LTP",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Strike",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "LTP",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "OI",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. LIST
        Expanded(
          child: Consumer<OptionChainProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.rows.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.rows.isEmpty) {
                return Center(
                  child: ElevatedButton(
                    onPressed: _fetchData,
                    child: const Text("Retry"),
                  ),
                );
              }

              final rows = provider.rows;
              return LayoutBuilder(
                builder: (ctx, c) {
                  if (provider.atmIndex != null) {
                    _scrollToAtm(provider.atmIndex!, c.maxHeight);
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      _hasScrolledToAtm = false;
                      _stopAutoRefresh();
                      await provider.fetchOptionChain();
                      _startAutoRefresh();
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: rows.length,
                      separatorBuilder: (ctx, i) {
                        final strike = rows[i].strikePrice;
                        final spot = provider.underlyingLtp ?? 0.0;
                        if (i + 1 < rows.length &&
                            spot >= strike &&
                            spot < rows[i + 1].strikePrice) {
                          return _buildSpot(spot);
                        }
                        return Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey.withOpacity(0.2),
                        );
                      },
                      itemBuilder: (ctx, i) {
                        final row = rows[i];
                        // Removed decoration logic for ATM
                        return Container(
                          key: ValueKey("${row.strikePrice}_${row.expiryDate}"),
                          color: Colors.black,
                          child: Row(
                            children: [
                              _buildSide(context, row, true),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: null, // No Highlight
                                    child: Text(
                                      row.strikePrice.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors
                                            .grey
                                            .shade400, // Uniform Color
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _buildSide(context, row, false),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSide(BuildContext context, dynamic row, bool isCall) {
    final Map<String, dynamic>? data = isCall ? row.ce : row.pe;
    final price = _fmtP(data?['lastPrice']);
    final chg = _fmtC(data?['pChange']);
    final oi = _formatOI(data?['openInterest'], data?['lotSize']);
    // Layout: Call = OI | Price+Change. Put = Price+Change | OI.
    return Expanded(
      flex: 4,
      child: InkWell(
        onTap: () => _onOptionTap(context, row, isCall),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _cell(
                isCall ? oi : price,
                isCall ? "" : chg,
                isCall ? null : _col(data?['pChange']),
              ),
              _cell(
                isCall ? price : oi,
                isCall ? chg : "",
                isCall ? _col(data?['pChange']) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String t, String s, Color? c) => Expanded(
    flex: 1,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            t,
            key: ValueKey(t),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c ?? Colors.white,
            ),
          ),
        ),
        if (s.isNotEmpty)
          Text(s, style: TextStyle(fontSize: 10, color: c ?? Colors.grey)),
      ],
    ),
  );

  Widget _buildSpot(double p) => Container(
    color: Colors.black,
    height: 30,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Divider(color: Colors.white, thickness: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            p.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// 3. OVERVIEW TAB
// ---------------------------------------------------------------------------
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  String _fmt(double? v) =>
      v == null || v == 0 ? "-" : NumberFormat("#,##0.00", "en_US").format(v);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OptionChainProvider>();
    final data = provider.overviewData;

    if (provider.isOverviewLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return const Center(
        child: Text("No Overview Data", style: TextStyle(color: Colors.grey)),
      );
    }

    final isNeg = data.priceChange < 0;
    return RefreshIndicator(
      onRefresh: () async => await provider.fetchMarketOverview(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.symbol,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _fmt(data.currentPrice),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${isNeg ? '' : '+'}${_fmt(data.priceChange)} (${data.percentChange.toStringAsFixed(2)}%)",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isNeg ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Performance",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _RangeLabels(
              "Today's Low",
              "Today's High",
              data.dayLow,
              data.dayHigh,
            ),
            const SizedBox(height: 8),
            MarketRangeSlider(
              low: data.dayLow,
              high: data.dayHigh,
              current: data.currentPrice,
            ),
            const SizedBox(height: 24),
            _RangeLabels(
              "52 Week Low",
              "52 Week High",
              data.yearLow,
              data.yearHigh,
            ),
            const SizedBox(height: 8),
            MarketRangeSlider(
              low: data.yearLow,
              high: data.yearHigh,
              current: data.currentPrice,
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 0.2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatItem("Open", _fmt(data.open))),
                Expanded(
                  child: _StatItem(
                    "Prev. Close",
                    _fmt(data.prevClose),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeLabels extends StatelessWidget {
  final String l, h;
  final double lv, hv;
  const _RangeLabels(this.l, this.h, this.lv, this.hv);
  @override
  Widget build(BuildContext context) {
    final f = NumberFormat("#,##0.00", "en_US");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text(
              lv == 0 ? "-" : f.format(lv),
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
            Text(h, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text(
              hv == 0 ? "-" : f.format(hv),
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
  final String l, v;
  final bool alignEnd;
  const _StatItem(this.l, this.v, {this.alignEnd = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(l, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class MarketRangeSlider extends StatelessWidget {
  final double low, high, current;
  const MarketRangeSlider({
    super.key,
    required this.low,
    required this.high,
    required this.current,
  });
  @override
  Widget build(BuildContext context) {
    if (low == 0 || high == 0) {
      return Container(height: 4, color: Colors.grey[800]);
    }
    double pct = ((current - low) / (high - low)).clamp(0.0, 1.0);
    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (ctx, c) => Stack(
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
              left: (c.maxWidth * pct).clamp(0.0, c.maxWidth - 12),
              child: const Icon(
                Icons.arrow_drop_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


