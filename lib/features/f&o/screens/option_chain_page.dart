import 'dart:async';
import 'package:bullxchange/features/f&o/screens/buy_option_page.dart';
import 'package:bullxchange/features/f&o/screens/charts_and_overview_tab.dart';
import 'package:bullxchange/features/f&o/screens/sell_option_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:bullxchange/utils/responsive_helper.dart';
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => OptionChainProvider(symbol: apiSymbol),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            widget.symbol,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodySmall?.color,
            indicatorColor: colorScheme.primary,
            labelStyle: TextStyle(
              fontSize: ResponsiveHelper.captionFontSize,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: ResponsiveHelper.captionFontSize,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Option Chain'),
              Tab(text: 'Charts & Overview'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [const _OptionChainBody(), const ChartsAndOverviewTab()],
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
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchData());
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

  final NumberFormat _lotsFormat = NumberFormat("#,##0", "en_US");

  String _formatOI(dynamic oiVal, dynamic lotSizeVal) {
    if (oiVal == null) return "-";
    double oi = double.tryParse(oiVal.toString()) ?? 0.0;
    if (oi == 0) return "-";
    int lotSize = int.tryParse(lotSizeVal?.toString() ?? "1") ?? 1;
    double lots = oi / lotSize;
    return _lotsFormat.format(lots);
  }

  Color _col(dynamic v) {
    final d = double.tryParse(v?.toString() ?? "0") ?? 0.0;
    return d > 0
        ? const Color(0xFF00C853) // Darker green for better visibility
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
      token: data['token']?.toString() ?? "",
      symbol: provider.symbol,
      name: provider.symbol,
      exchSeg: "F&O",
      expiry: row.expiryDate,
      strike: row.strikePrice.toString(),
      instrumentType: "OPTIDX",
      lotSize:
          data['lotSize']?.toString() ??
          "50", // Default to "50" if null or invalid
      outstandingShares: 0,
      avgVolume: 0,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
    final theme = Theme.of(context);
    final isCall = type == "CE";

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.5 : 0.3,
            ),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header with option details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$sym $strike $type",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Option Contract",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCall
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "₹${ltp.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: isCall
                                ? const Color(
                                    0xFF00C853,
                                  ) // Darker green for better visibility
                                : Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buy/Sell buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.trending_up, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                "BUY",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.trending_down, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                "SELL",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExpiryPicker(BuildContext context, OptionChainProvider provider) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select Expiry",
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
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
                        color: isSel
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      children: [
        // 1. HEADER (Call | Expiry Dropdown | Put)
        Consumer<OptionChainProvider>(
          builder: (context, provider, _) {
            final expiryText = provider.selectedExpiry?.isNotEmpty == true
                ? provider.selectedExpiry!
                : "Current";
            return Container(
              color: theme.scaffoldBackgroundColor,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.smallSpacing,
                horizontal: ResponsiveHelper.horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Call price",
                    style: textTheme.bodySmall?.copyWith(
                      color: textTheme.bodySmall?.color,
                      fontSize: ResponsiveHelper.captionFontSize,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showExpiryPicker(context, provider),
                    child: Row(
                      children: [
                        Text(
                          expiryText,
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: ResponsiveHelper.smallFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.tinySpacing),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.onSurface,
                          size: ResponsiveHelper.iconSize * 0.75,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Put price",
                    style: textTheme.bodySmall?.copyWith(
                      color: textTheme.bodySmall?.color,
                      fontSize: ResponsiveHelper.captionFontSize,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // 2. COLUMNS HEADER
        Container(
          color: theme.cardColor,
          padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.tinySpacing),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "OI",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "LTP",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Strike",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "LTP",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "OI",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
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
                  _scrollToAtm(provider.atmIndex, c.maxHeight);
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
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        );
                      },
                      itemBuilder: (ctx, i) {
                        final row = rows[i];
                        // Removed decoration logic for ATM
                        return Container(
                          key: ValueKey("${row.strikePrice}_${row.expiryDate}"),
                          color: theme.scaffoldBackgroundColor,
                          child: Row(
                            children: [
                              _buildSide(context, row, true),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveHelper.tinySpacing,
                                      vertical:
                                          ResponsiveHelper.tinySpacing * 0.5,
                                    ),
                                    decoration: null, // No Highlight
                                    child: Text(
                                      row.strikePrice.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            ResponsiveHelper.smallFontSize,
                                        color: theme.textTheme.bodySmall?.color,
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
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.smallSpacing,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _cell(
                  isCall ? oi : price,
                  isCall ? "" : chg,
                  isCall ? null : _col(data?['pChange']),
                ),
              ),
              Expanded(
                flex: 2,
                child: _cell(
                  isCall ? price : oi,
                  isCall ? chg : "",
                  isCall ? _col(data?['pChange']) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String t, String s, Color? c) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Expanded(
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
                fontSize: ResponsiveHelper.smallFontSize,
                fontWeight: FontWeight.w500,
                color: c ?? textTheme.bodyMedium?.color,
              ),
            ),
          ),
          if (s.isNotEmpty)
            Text(
              s,
              style: TextStyle(
                fontSize: ResponsiveHelper.tinyFontSize,
                color: c ?? textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpot(double p) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: theme.scaffoldBackgroundColor,
      height: ResponsiveHelper.listItemHeight * 0.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            thickness: 1,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.smallSpacing,
              vertical: ResponsiveHelper.tinySpacing,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.cardBorderRadius,
              ),
            ),
            child: Text(
              p.toStringAsFixed(2),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.smallFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final provider = context.watch<OptionChainProvider>();
    final data = provider.overviewData;

    if (provider.isOverviewLoading && data == null) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    final isNeg = data.priceChange < 0;
    return RefreshIndicator(
      onRefresh: () async => await provider.fetchMarketOverview(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.symbol,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: ResponsiveHelper.h2FontSize,
              ),
            ),
            SizedBox(height: ResponsiveHelper.tinySpacing),
            Row(
              children: [
                Text(
                  _fmt(data.currentPrice),
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: ResponsiveHelper.h3FontSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.tinySpacing),
                Text(
                  "${isNeg ? '' : '+'}${_fmt(data.priceChange)} (${data.percentChange.toStringAsFixed(2)}%)",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveHelper.captionFontSize,
                    fontWeight: FontWeight.w500,
                    color: isNeg
                        ? Colors.redAccent
                        : const Color(
                            0xFF00C853,
                          ), // Darker green for better visibility
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.sectionSpacing),
            Text(
              "Performance",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: ResponsiveHelper.captionFontSize,
              ),
            ),
            SizedBox(height: ResponsiveHelper.itemSpacing),
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
            Divider(
              color: theme.dividerColor.withValues(alpha: 0.2),
              thickness: 0.2,
            ),
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
    final theme = Theme.of(context);
    final f = NumberFormat("#,##0.00", "en_US");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            Text(
              lv == 0 ? "-" : f.format(lv),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(h, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            Text(
              hv == 0 ? "-" : f.format(hv),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 15,
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
    final theme = Theme.of(context);
    if (low == 0 || high == 0) {
      return Container(
        height: 4,
        color: theme.dividerColor.withValues(alpha: 0.3),
      );
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
                color: theme.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Positioned(
              left: (c.maxWidth * pct).clamp(0.0, c.maxWidth - 12),
              child: Icon(
                Icons.arrow_drop_up,
                color: theme.textTheme.bodyMedium?.color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
