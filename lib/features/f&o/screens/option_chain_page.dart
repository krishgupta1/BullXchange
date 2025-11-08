import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- This is the main page widget with the TabBar ---
// (No changes here)
class OptionChainPage extends StatefulWidget {
  final String symbol; // e.g., "NIFTY"

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

// --- This widget sets up the Provider for the Option Chain ---
// (No changes here)
class _OptionChainTab extends StatelessWidget {
  final String symbol;

  const _OptionChainTab({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OptionChainProvider(symbol: symbol),
      child: const _OptionChainBody(),
    );
  }
}

// --- This widget is the actual UI for the Option Chain ---
// ⭐️ (UPDATED TO HIGHLIGHT THE ATM STRIKE) ⭐️

class _OptionChainBody extends StatelessWidget {
  const _OptionChainBody();

  String _safeNum(dynamic v) {
    if (v == null) return "-";
    final parsed = num.tryParse(v.toString());
    return parsed != null ? parsed.toStringAsFixed(2) : v.toString();
  }

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
    // ⭐️ 1. Get the ATM index and LTP from the provider
    final int? atmIndex = provider.atmIndex;
    final double? ltp = provider.underlyingLtp;

    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          "${provider.symbol} OPTION CHAIN (NSE)",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // ⭐️ 2. Display the live LTP
        if (ltp != null) ...[
          const SizedBox(height: 4),
          Text(
            "Live Price: ${ltp.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              Expanded(flex: 2, child: Center(child: Text("CE OI"))),
              Expanded(flex: 2, child: Center(child: Text("CE LTP"))),
              Expanded(flex: 2, child: Center(child: Text("Strike"))),
              Expanded(flex: 2, child: Center(child: Text("PE LTP"))),
              Expanded(flex: 2, child: Center(child: Text("PE OI"))),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchOptionChain(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final ce = row.ce;
                final pe = row.pe;

                // ⭐️ 3. Check if this row is the ATM row
                final bool isAtm = (atmIndex != null && atmIndex == index);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    // ⭐️ 4. Apply a background color if it's the ATM strike
                    color: isAtm ? Colors.yellow.shade100 : null,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(_safeNum(ce?['openInterest'] ?? '')),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(_safeNum(ce?['lastPrice'] ?? '')),
                        ),
                      ),
                      // ⭐️ 5. Make the ATM strike price bold
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            row.strikePrice.toString(),
                            style: TextStyle(
                              fontWeight: isAtm
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isAtm ? Colors.black : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(_safeNum(pe?['lastPrice'] ?? '')),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(_safeNum(pe?['openInterest'] ?? '')),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}
