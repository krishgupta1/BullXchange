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
    if (s == "NIFTY MID SELECT" ||
        s.contains("MID SELECT") ||
        s.contains("MIDCPNIFTY")) {
      return "MIDCPNIFTY";
    }
    if (s == "BANKEX") return "BANKEX";
    if (s == "SENSEX") return "SENSEX";
    if (s == "FINNIFTY" || s.contains("FINANCIAL")) return "FINNIFTY";
    if (s == "BANKNIFTY" || s == "BANK NIFTY") return "BANKNIFTY";
    if (s == "NIFTY" || s == "NIFTY 50" || s == "NIFTY50") return "NIFTY";
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final apiSymbol = _getApiSymbol(widget.symbol);

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
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
          ChangeNotifierProvider(
            create: (_) => OptionChainProvider(symbol: apiSymbol),
            child: const _OptionChainBody(),
          ),
          const Center(child: Text("Overview")),
          const Center(child: Text("Charts")),
        ],
      ),
    );
  }
}

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

  // --- ⭐️ FIXED FORMATTERS (Hides 0s) ---
  String _formatPrice(dynamic v) {
    if (v == null) return "-";
    final p = double.tryParse(v.toString()) ?? 0.0;
    if (p == 0) return "-"; // ⭐️ Shows - instead of 0.00
    return p.toStringAsFixed(2);
  }

  String _formatChange(dynamic v) {
    if (v == null) return "";
    final p = double.tryParse(v.toString()) ?? 0.0;
    if (p == 0) return "-"; // ⭐️ Shows - instead of 0.00%
    return "${p > 0 ? '+' : ''}${p.toStringAsFixed(2)}%";
  }

  String _formatOI(dynamic oiVal, dynamic lotSizeVal) {
    if (oiVal == null) return "-";
    double oi = double.tryParse(oiVal.toString()) ?? 0.0;
    if (oi == 0) return "-"; // ⭐️ Shows - instead of 0

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
              _scrollToAtm(atmIndex!, constraints.maxHeight);
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
          // ⭐️ ONLY SHOW IF NOT "-"
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
