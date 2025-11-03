import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/screens/view_all_page.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  // Create instances to use
  final UserService _userService = UserService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Center(child: Text("Please log in."));
    }

    // This StreamBuilder listens to real-time changes in the user's profile
    return StreamBuilder<UserProfileDataModel?>(
      stream: _userService.streamUserProfile(uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Could not load user profile."));
        }

        // Get the dynamic watchlist tokens from the user's profile
        final userProfile = snapshot.data!;
        final userWatchlistTokens = userProfile.watchlist;

        // The rest of your code now uses the dynamic list
        return Consumer<InstrumentProvider>(
          builder: (context, provider, child) {
            final watchlistStocks = provider.allNSEStocks
                .where((stock) => userWatchlistTokens.contains(stock.token))
                .toList();

            if (watchlistStocks.isEmpty) {
              return const _EmptyState();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildWatchlistHeader(watchlistStocks.length, context),
                      const SizedBox(height: 16),
                      _buildSortHeader(),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // --- Watchlist stocks ---
                ...watchlistStocks.map((instrument) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StockDetailPage(instrument: instrument),
                        ),
                      );
                    },
                    child: _buildStockItem(instrument: instrument),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

// --- Reusable Widgets (from your original file) ---

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 20),
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

Widget _buildWatchlistHeader(int stockCount, BuildContext context) {
  return Row(
    children: [
      Text(
        "$stockCount stocks",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.add_box_outlined),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ViewAllPage()),
          );
        },
      ),
      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
    ],
  );
}

Widget _buildSortHeader() {
  return Row(
    children: [
      TextButton.icon(
        icon: const Icon(Icons.sort, color: Colors.black54),
        label: const Text("Sort", style: TextStyle(color: Colors.black54)),
        onPressed: () {},
      ),
      const Spacer(),
      Text(
        "Mkt price / 1D <>",
        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
      ),
    ],
  );
}

Widget _buildStockItem({required Instrument instrument}) {
  final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final changeColor = netChange >= 0 ? Colors.green : Colors.red;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      children: [
        SmartLogo(instrument: instrument, radius: 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
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
      ],
    ),
  );
}
