// lib/pages/future_option_explore_page.dart

import 'package:bullxchange/models/future_option_instrument_model.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/future_option_instrument_provider.dart';
import 'package:bullxchange/provider/instrument_provider.dart'; // ✨ WE NEED THIS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FutureOptionExplorePage extends StatelessWidget {
  const FutureOptionExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- 1. TOP CARDS (SPOT INDICES) ---
        // This Consumer gets data from InstrumentProvider
        Consumer<InstrumentProvider>(
          builder: (context, instProvider, child) {
            // Get all 6 spot indices
            final indices = [
              instProvider.nifty50,
              instProvider.bankNifty,
              instProvider.finNifty,
              instProvider.midcapNifty,
              instProvider.sensex,
              instProvider.bankex,
            ];

            if (instProvider.isLoading && instProvider.nifty50?.token == '') {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Build a scrolling grid for the 6 cards
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cards per row
                childAspectRatio: 2.2, // Adjust for card height
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              padding: const EdgeInsets.all(12.0),
              itemCount: indices.length,
              shrinkWrap: true, // Fit to content
              physics:
                  const NeverScrollableScrollPhysics(), // Disable grid scroll
              itemBuilder: (context, index) {
                return _buildIndexCard(instrument: indices[index]);
              },
            );
          },
        ),

        // --- 2. BOTTOM LIST (FUTURES CONTRACTS) ---
        // This Consumer gets data from FutureOptionProvider
        Expanded(
          child: Consumer<FutureOptionProvider>(
            builder: (context, fnoProvider, child) {
              final mainIndexes = fnoProvider.mainIndexFutures;

              if (fnoProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (fnoProvider.errorMessage != null) {
                return Center(child: Text(fnoProvider.errorMessage!));
              }

              if (mainIndexes.isEmpty) {
                return const Center(
                  child: Text(
                    'No main index futures found.\nCheck your JSON file.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Build the list of F&O contracts
              return ListView.separated(
                itemCount: mainIndexes.length,
                itemBuilder: (context, index) {
                  final instrument = mainIndexes[index];
                  return _buildIndexFutureTile(instrument);
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGET FOR TOP CARDS (from StockPage) ---
  Widget _buildIndexCard({required Instrument? instrument}) {
    // Use 'symbol' as the title, as 'name' can be long
    final name = instrument?.symbol?.toUpperCase() ?? "LOADING...";
    final value = instrument?.liveData["ltp"]?.toString() ?? "--";
    final netChange = instrument?.liveData["netChange"]?.toString() ?? "0";
    final percentChange =
        instrument?.liveData["percentChange"]?.toString() ?? "0";
    final double changeValue = num.tryParse(netChange)?.toDouble() ?? 0.0;
    final changeColor = changeValue >= 0 ? Colors.green : Colors.red;
    final changeText = "$netChange ($percentChange%)";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value != "--" ? "₹$value" : value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              color: changeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGET FOR F&O LIST (from previous step) ---
  Widget _buildIndexFutureTile(FutureOptionInstrument contract) {
    // Extract live data
    final liveData = contract.liveData;
    final ltp = (liveData['ltp'] is num) ? liveData['ltp'].toDouble() : 0.0;
    final pChange = (liveData['percentChange'] is num)
        ? liveData['percentChange'].toDouble()
        : 0.0;
    final netChange = (liveData['netChange'] is num)
        ? liveData['netChange'].toDouble()
        : 0.0;

    final isPositive = netChange >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return ListTile(
      onTap: () {
        // TODO: Navigate to contract details
      },
      title: Text(
        contract.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        'Expiry: ${contract.expiry}', // Show expiry date
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            ltp.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ltp == 0.0 ? Colors.grey : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${netChange.toStringAsFixed(2)} (${pChange.toStringAsFixed(2)}%)',
            style: TextStyle(color: changeColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
