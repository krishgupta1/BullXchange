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
  final UserService _userService = UserService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  bool _isEditMode = false;
  final Set<String> _selectedTokens = {};

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectedTokens.clear();
    });
  }

  void _toggleSelection(String token) {
    setState(() {
      if (_selectedTokens.contains(token)) {
        _selectedTokens.remove(token);
      } else {
        _selectedTokens.add(token);
      }
    });
  }

  void _deleteSelectedStocks() async {
    if (uid == null || _selectedTokens.isEmpty) return;

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Stocks?'),
        content: Text(
          'Are you sure you want to remove ${_selectedTokens.length} stock(s) from your watchlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (didConfirm != true) return;

    try {
      final tokensToRemove = _selectedTokens.toList();
      for (final token in tokensToRemove) {
        await _userService.toggleWatchlistStock(uid!, token);
      }
      _toggleEditMode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing stocks: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Center(child: Text("Please log in."));
    }

    return StreamBuilder<UserProfileDataModel?>(
      stream: _userService.streamUserProfile(uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Could not load user profile."));
        }

        final userProfile = snapshot.data!;
        final userWatchlistTokens = userProfile.watchlist;

        return Consumer<InstrumentProvider>(
          builder: (context, provider, child) {
            final watchlistStocks = provider.allNSEStocks
                .where((stock) => userWatchlistTokens.contains(stock.token))
                .toList();

            if (watchlistStocks.isEmpty && !_isEditMode) {
              return const Center(child: _EmptyState());
            }

            // --- ⭐️ FIX: The root widget is a COLUMN. ---
            // It is NOT scrollable. Its parent page provides the scrolling.
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildWatchlistHeader(
                        watchlistStocks.length,
                        context,
                        _isEditMode,
                        _toggleEditMode,
                        _deleteSelectedStocks,
                        _selectedTokens.isNotEmpty,
                      ),
                      const SizedBox(height: 16),
                      _buildSortHeader(),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // --- ⭐️ FIX: The list items are spread directly into the Column. ---
                // There is NO ListView and NO Expanded widget.
                ...watchlistStocks.map((instrument) {
                  final isSelected = _selectedTokens.contains(instrument.token);

                  return InkWell(
                    onTap: () {
                      if (_isEditMode) {
                        _toggleSelection(instrument.token);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockDetailPage(instrument: instrument),
                          ),
                        );
                      }
                    },
                    child: _buildStockItem(
                      instrument: instrument,
                      isEditMode: _isEditMode,
                      isSelected: isSelected,
                    ),
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

// --- (All other widgets below this are unchanged and correct) ---

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
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

Widget _buildWatchlistHeader(
  int stockCount,
  BuildContext context,
  bool isEditMode,
  VoidCallback onToggleEdit,
  VoidCallback onDeleteSelected,
  bool hasSelection,
) {
  return Row(
    children: [
      Text(
        isEditMode ? "Select Stocks" : "$stockCount stocks",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      if (isEditMode) ...[
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: hasSelection ? Colors.red : Colors.grey,
          ),
          onPressed: hasSelection ? onDeleteSelected : null,
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: onToggleEdit),
      ] else ...[
        IconButton(
          icon: const Icon(Icons.add_box_outlined),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ViewAllPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onToggleEdit,
        ),
      ],
    ],
  );
}

Widget _buildSortHeader() {
  return Row(
    children: [
      TextButton.icon(
        icon: const Icon(Icons.sort, color: Colors.black54, size: 18),
        label: const Text("Sort", style: TextStyle(color: Colors.black54)),
        onPressed: () {},
      ),
      const Spacer(),
      Text(
        "Mkt price / 1D <>",
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ],
  );
}

Widget _buildStockItem({
  required Instrument instrument,
  bool isEditMode = false,
  bool isSelected = false,
}) {
  final ltp = (instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
  final netChange =
      (instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
  final percentChange =
      (instrument.liveData['percentChange'] as num?)?.toDouble() ?? 0.0;
  final changeColor = netChange >= 0 ? const Color(0xFF1EAB58) : Colors.red;

  return Container(
    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    child: Row(
      children: [
        if (isEditMode)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IgnorePointer(
              child: Checkbox(
                value: isSelected,
                onChanged: (val) {},
                activeColor: Colors.blue,
              ),
            ),
          ),
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
                  fontSize: 12,
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
          width: 80,
          height: 40,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Row(
              children: [
                Icon(
                  percentChange >= 0
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: changeColor,
                  size: 20,
                ),
                Text(
                  "${percentChange.abs().toStringAsFixed(2)}%",
                  style: TextStyle(color: changeColor, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
