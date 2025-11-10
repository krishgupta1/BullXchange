import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math; // Used for OI bars

// --- Main Page Widget (No changes) ---
class OptionChainPage extends StatefulWidget {
  final String symbol; // e.g., "Nifty 50"

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        // We'll add the expiry dropdown here later
        // actions: [ _buildExpiryDropdown() ], 
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
          // --- Tab 1: Option Chain ---
          _OptionChainTab(symbol: widget.symbol),

          // --- Tab 2: Overview (Placeholder) ---
          const Center(
            child: Text(
              'Overview Page Content',
              style: TextStyle(fontSize: 18),
            ),
          ),

          // --- Tab 3: Charts (Placeholder) ---
          const Center(
            child: Text('Charts Page Content', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// --- Provider Setup (No changes) ---
class _OptionChainTab extends StatelessWidget {
  final String symbol;

  const _OptionChainTab({required this.symbol});

  @override
  Widget build(BuildContext context) {
    // We wrap this in a ChangeNotifierProvider
    return ChangeNotifierProvider(
      create: (_) => OptionChainProvider(symbol: symbol),
      child: const _OptionChainBody(),
    );
  }
}

// ---
// --- 🚀 NEW UI BODY STARTS HERE 🚀 ---
// ---

// We need a StatefulWidget to hold the state of the "OI" / "Price" toggle
class _OptionChainBody extends StatefulWidget {
  const _OptionChainBody();

  @override
  State<_OptionChainBody> createState() => _OptionChainBodyState();
}

class _OptionChainBodyState extends State<_OptionChainBody> {
  // true = Price view, false = OI view
  bool _isPriceView = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OptionChainProvider>();

    if (provider.isLoading && provider.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.rows.isEmpty) {
      return Center(child: Text(provider.error!));
    }

    final rows = provider.rows;
    final int? atmIndex = provider.atmIndex;

    return Column(
      children: [
        // --- 1. Live Price Header (The "Pill") ---
        _buildLivePriceHeader(provider),

        // --- 2. OI / Price Toggle ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleButtons(
            isSelected: [_isPriceView, !_isPriceView],
            onPressed: (index) {
              setState(() {
                _isPriceView = (index == 0);
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: Colors.blue.shade700,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Price'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('OI'),
              ),
            ],
          ),
        ),

        // --- 3. The 3-Column Header ---
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Call Price', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Strike', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Put Price', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        // --- 4. The Option Chain List ---
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchOptionChain(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final isAtm = (atmIndex != null && atmIndex == index);

                return _StrikeRow(
                  row: row,
                  isAtm: isAtm,
                  isPriceView: _isPriceView,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Helper for the "Pill" at the top
  Widget _buildLivePriceHeader(OptionChainProvider provider) {
    final double ltp = provider.underlyingLtp ?? 0.0;
    // ASSUMPTION: Your provider now has these properties
    final double change = (provider.underlyingLtpChange as num?)?.toDouble() ?? 0.0;
    final double percent = (provider.underlyingLtpPercent as num?)?.toDouble() ?? 0.0;
    
    final Color color = change >= 0 ? Colors.green : Colors.red;
    final String sign = change >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          text: ltp.toStringAsFixed(2),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          children: [
            TextSpan(
              text: '  $sign${change.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontSize: 13),
            ),
            TextSpan(
              text: ' ($sign${percent.toStringAsFixed(2)}%)',
              style: TextStyle(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ---
// --- 🚀 NEW WIDGETS FOR THE LIST ROWS 🚀 ---
// ---

/// This widget builds a single 3-column row
class _StrikeRow extends StatelessWidget {
  final OptionChainRow row;
  final bool isAtm;
  final bool isPriceView;

  const _StrikeRow({
    required this.row,
    required this.isAtm,
    required this.isPriceView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isAtm ? Colors.yellow.shade100 : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // --- 1. Call Column ---
          Expanded(
            child: _DataCell(
              isCall: true,
              isPriceView: isPriceView,
              data: row.ce,
            ),
          ),
          
          // --- 2. Strike Column (with OI Bar) ---
          Expanded(
            child: _StrikeCell(
              strike: row.strikePrice,
              ceOi: (row.ce?['openInterest'] as num?)?.toDouble() ?? 0,
              peOi: (row.pe?['openInterest'] as num?)?.toDouble() ?? 0,
            ),
          ),

          // --- 3. Put Column ---
          Expanded(
            child: _DataCell(
              isCall: false,
              isPriceView: isPriceView,
              data: row.pe,
            ),
          ),
        ],
      ),
    );
  }
}

/// This widget shows either Price+Percent OR OI
class _DataCell extends StatelessWidget {
  final bool isCall;
  final bool isPriceView;
  final Map<String, dynamic>? data;

  const _DataCell({
    required this.isCall,
    required this.isPriceView,
    this.data,
  });

  String _safeNum(dynamic v, {int decimals = 2}) {
    final parsed = num.tryParse(v.toString());
    return parsed != null ? parsed.toStringAsFixed(decimals) : "-";
  }

  @override
  Widget build(BuildContext context) {
    final double ltp = (data?['lastPrice'] as num?)?.toDouble() ?? 0.0;
    // ASSUMPTION: Your provider sends this
    final double percent = (data?['priceChangePercent'] as num?)?.toDouble() ?? 0.0; 
    final double oi = (data?['openInterest'] as num?)?.toDouble() ?? 0.0;
    // ASSUMPTION: Your provider sends this
    final double iv = (data?['iv'] as num?)?.toDouble() ?? 0.0;

    final Color color = percent >= 0 ? Colors.green : Colors.red;
    final String sign = percent >= 0 ? '+' : '';
    final Alignment align = isCall ? Alignment.centerLeft : Alignment.centerRight;

    return Align(
      alignment: align,
      child: Visibility(
        visible: isPriceView,
        // --- Or, Show OI ---
        replacement: Text(
          _safeNum(oi, decimals: 0),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        // --- Show Price + Percent ---
        child: Column(
          crossAxisAlignment: isCall ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              _safeNum(ltp),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '$sign${_safeNum(percent)}%',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// This widget shows the Strike Price + OI Bar
class _StrikeCell extends StatelessWidget {
  final double strike;
  final double ceOi;
  final double peOi;

  const _StrikeCell({
    required this.strike,
    required this.ceOi,
    required this.peOi,
  });

  @override
  Widget build(BuildContext context) {
    final double totalOi = ceOi + peOi;
    // Use max(1) to prevent divide-by-zero if totalOi is 0
    final double ceFlex = (ceOi / math.max(1, totalOi)) * 100;
    final double peFlex = (peOi / math.max(1, totalOi)) * 100;

    return Column(
      children: [
        // 1. The Strike Price Text
        Text(
          strike.toStringAsFixed(0),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // 2. The OI Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                // Call OI Bar (Green)
                Flexible(
                  flex: ceFlex.toInt(),
                  child: Container(color: Colors.green),
                ),
                // Put OI Bar (Red)
                Flexible(
                  flex: peFlex.toInt(),
                  child: Container(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}