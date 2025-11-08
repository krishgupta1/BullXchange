import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FutureOptionPositionPage extends StatelessWidget {
  const FutureOptionPositionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OptionChainProvider(symbol: 'NIFTY'), // or BANKNIFTY
      child: const _OptionChainBody(),
    );
  }
}

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

    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          "${provider.symbol} OPTION CHAIN (NSE)",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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

                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Center(
                            child:
                                Text(_safeNum(ce?['openInterest'] ?? ''))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                            child:
                                Text(_safeNum(ce?['lastPrice'] ?? ''))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                            child:
                                Text(row.strikePrice.toString())),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                            child:
                                Text(_safeNum(pe?['lastPrice'] ?? ''))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                            child:
                                Text(_safeNum(pe?['openInterest'] ?? ''))),
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
