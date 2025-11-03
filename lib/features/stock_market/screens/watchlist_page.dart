import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/provider/user_profile_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart'; // Assuming this exists

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Authentication and Provider initialization)
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? uid = currentUser?.uid;

    final userProfileProvider = context.watch<UserProfileProvider>();
    final instrumentProvider = context.watch<InstrumentProvider>();
    final UserService userService = context.read<UserService>();

    if (uid == null) {
      return const Center(child: Text("Please login to view your watchlist."));
    }

    // ⭐ FIX 1: SYNCHRONIZATION AND LOADING CHECK
    // यदि InstrumentProvider मास्टर लिस्ट लोड कर रहा है OR UserProfileProvider ने अभी तक Firebase से डेटा प्राप्त नहीं किया है, तो Spinner दिखाओ।
    if (userProfileProvider.userProfile == null || instrumentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // ⭐ FIX 2: WRAP IN SCAFFOLD FOR BOUNDED CONSTRAINTS (Layout fix)
    return Scaffold(
      body: _buildWatchlistContent(context, uid, userProfileProvider, instrumentProvider, userService),
    );
  }
  
  // Helper to contain the main list logic
  Widget _buildWatchlistContent(
    BuildContext context,
    String uid,
    UserProfileProvider userProfileProvider,
    InstrumentProvider instrumentProvider,
    UserService userService,
  ) {
    final List<StockHoldingModel> watchlistItems =
        userProfileProvider.userProfile?.watchlist ?? [];

    final watchlistInstruments = watchlistItems
        .map(
          (item) => instrumentProvider.getInstrumentBySymbol(item.stockSymbol),
        )
        .whereType<Instrument>()
        .toList();

    // Trigger live data fetch (Prices for these specific stocks)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      instrumentProvider.fetchLiveDataFor(watchlistInstruments);
    });
    
    // Check 2: Empty State
    if (watchlistInstruments.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildWatchlistHeader(watchlistInstruments.length),
              const SizedBox(height: 16),
              _buildSortHeader(),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),

        // --- Watchlist stocks (Renders Firebase data with live prices) ---
        Expanded( // Now safe inside the Column which is inside a Scaffold body
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: watchlistInstruments.length,
            itemBuilder: (context, index) {
              final instrument = watchlistInstruments[index];

              return InkWell(
                onTap: () {
                  // TODO: Navigate to Stock Details Page
                },
                child: _buildStockItem(
                  instrument: instrument,
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                    onPressed: () {
                      final itemToRemove = StockHoldingModel(
                        stockSymbol: instrument.symbol.replaceAll('-EQ', ''),
                        stockName: instrument.name,
                        exchange: instrument.exchSeg,
                        quantity: 0,
                        transactionPrice: 0.0,
                        transactionType: 'WLIST',
                        charges: 0.0,
                        totalAmount: 0.0,
                        buyingTime: DateTime.fromMillisecondsSinceEpoch(0),
                      );

                      userService.toggleWatchlistItem(
                        uid: uid,
                        stockItem: itemToRemove,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


// ----------------------------------------------------------------------
// --- Helper Widgets (Included for complete functionality) ---
// ----------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 50), // Added spacing for better center alignment
        Icon(
          Icons.star_border_purple500_outlined,
          size: 48,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Text(
          "Your Watchlist is Empty",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Add stocks to your watchlist to track them easily.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget _buildWatchlistHeader(int stockCount) {
  return Row(
    children: [
      Text(
        "$stockCount stocks",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: () {
        // TODO: Navigation to stock search/add page
      }),
      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {
        // TODO: Enable edit/reorder mode
      }),
    ],
  );
}

Widget _buildSortHeader() {
  return Row(
    children: [
      TextButton.icon(
        icon: const Icon(Icons.sort, color: Colors.black54),
        label: const Text("Sort", style: TextStyle(color: Colors.black54)),
        onPressed: () {
          // TODO: Implement sort action
        },
      ),
      const Spacer(),
      Text(
        "Mkt price / 1D <>",
        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
      ),
    ],
  );
}

Widget _buildStockItem({required Instrument instrument, Widget? trailing}) {
  final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final changeColor = netChange >= 0 ? Colors.green : Colors.red;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      children: [
        _buildLogoContainer(instrument.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // This displays the symbol from the Instrument (e.g., CONFIPET)
                instrument.symbol.replaceAll('-EQ', ''), 
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                instrument.name,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 30,
          child: MiniChart.fromInstrument(
            instrument: instrument,
            color: changeColor,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₹${ltp.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "(${netChange.toStringAsFixed(2)})",
              style: TextStyle(color: changeColor, fontSize: 12),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}

Widget _buildLogoContainer(String name) {
  // Simple logo logic (using SVGs/images requires proper network access/setup)
  final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
  final color = Colors.primaries[name.hashCode % Colors.primaries.length];
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}