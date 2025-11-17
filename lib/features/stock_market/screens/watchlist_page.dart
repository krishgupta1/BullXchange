import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/screens/view_all_page.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
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

    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // --- ⭐️ MODIFIED: Theme-aware dialog ---
        backgroundColor: colorScheme.surface,
        title: Text(
          'Remove Stocks?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to remove ${_selectedTokens.length} stock(s) from your watchlist?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: colorScheme.error),
            ), // Red
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
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (uid == null) {
      return Center(
        child: Text(
          "Please log in to see your watchlist.",
          style: TextStyle(color: colorScheme.onSurface),
        ),
      );
    }

    // --- ⭐️⭐️ FIX: Ab yeh sirf user data (bookmark list) ke liye rebuild hoga ---
    return StreamBuilder<UserProfileDataModel?>(
      stream: _userService.streamUserProfile(uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Text(
              "Could not load user profile.",
              style: TextStyle(color: colorScheme.onSurface),
            ),
          );
        }

        final userProfile = snapshot.data!;
        final userWatchlistTokens = userProfile.watchlist;

        // --- ⭐️ Provider ko 'listen: false' se get kiya ---
        final provider = Provider.of<InstrumentProvider>(
          context,
          listen: false,
        );

        // Stocks ki list ek hi baar banayi
        final watchlistStocks = provider.allNSEStocks
            .where((stock) => userWatchlistTokens.contains(stock.token))
            .toList();

        if (watchlistStocks.isEmpty && !_isEditMode) {
          return const Center(child: _EmptyState());
        }

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
                  _buildSortHeader(context), // ⭐️ Pass context
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerColor.withOpacity(0.1),
            ),

            // --- ⭐️⭐️ FIX: Expanded ko hata diya ⭐️⭐️ ---
            // ListView.builder ko shrinkWrap aur physics di
            ListView.builder(
              shrinkWrap: true, // <-- ADDED
              physics: const NeverScrollableScrollPhysics(), // <-- ADDED
              itemCount: watchlistStocks.length,
              itemBuilder: (context, index) {
                final instrumentToken =
                    watchlistStocks[index].token; // ⭐️ Sirf token pass kiya
                final isSelected = _selectedTokens.contains(instrumentToken);

                return InkWell(
                  onTap: () {
                    if (_isEditMode) {
                      _toggleSelection(instrumentToken);
                    } else {
                      // Poora instrument object get kiya
                      final instrument = provider.getInstrumentByToken(
                        instrumentToken,
                      );
                      if (instrument != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockDetailPage(instrument: instrument),
                          ),
                        );
                      }
                    }
                  },
                  // --- ⭐️⭐️ FIX: Naya listening widget use kiya ---
                  child: _WatchlistStockItem(
                    token: instrumentToken,
                    isEditMode: _isEditMode,
                    isSelected: isSelected,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// --- (Empty State Widget - Theme-Aware) ---
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.bookmark_border,
          size: 48,
          // --- ⭐️ MODIFIED: Theme grey color ---
          color: textTheme.bodySmall?.color,
        ),
        const SizedBox(height: 16),
        Text(
          "Your Watchlist is Empty",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            // --- ⭐️ MODIFIED: Theme text color ---
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add stocks to your watchlist to track them easily.",
          // --- ⭐️ MODIFIED: Theme grey color ---
          style: TextStyle(color: textTheme.bodySmall?.color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// --- (Watchlist Header Widget - Theme-Aware) ---
Widget _buildWatchlistHeader(
  int stockCount,
  BuildContext context,
  bool isEditMode,
  VoidCallback onToggleEdit,
  VoidCallback onDeleteSelected,
  bool hasSelection,
) {
  // --- ⭐️ Theme se colors lo ---
  final colorScheme = Theme.of(context).colorScheme;

  return Row(
    children: [
      Text(
        isEditMode ? "Select Stocks" : "$stockCount stocks",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          // --- ⭐️ MODIFIED: Theme text color ---
          color: colorScheme.onSurface,
        ),
      ),
      const Spacer(),
      if (isEditMode) ...[
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            // --- ⭐️ MODIFIED: Theme error/grey color ---
            color: hasSelection ? colorScheme.error : Colors.grey,
          ),
          onPressed: hasSelection ? onDeleteSelected : null,
        ),
        // --- ⭐️ MODIFIED: Theme icon color ---
        IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: onToggleEdit,
        ),
      ] else ...[
        IconButton(
          // --- ⭐️ MODIFIED: Theme icon color ---
          icon: Icon(Icons.add_box_outlined, color: colorScheme.onSurface),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewAllPage()),
            );
          },
        ),
        IconButton(
          // --- ⭐️ MODIFIED: Theme icon color ---
          icon: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
          onPressed: onToggleEdit,
        ),
      ],
    ],
  );
}

// --- (Sort Header Widget - Theme-Aware) ---
Widget _buildSortHeader(BuildContext context) {
  // --- ⭐️ Theme se colors lo ---
  final textTheme = Theme.of(context).textTheme;

  return Row(
    children: [
      TextButton.icon(
        icon: Icon(
          Icons.sort,
          // --- ⭐️ MODIFIED: Theme grey color ---
          color: textTheme.bodySmall?.color,
          size: 18,
        ),
        label: Text(
          "Sort",
          // --- ⭐️ MODIFIED: Theme grey color ---
          style: TextStyle(color: textTheme.bodySmall?.color),
        ),
        onPressed: () {},
      ),
      const Spacer(),
      Text(
        "Mkt price / 1D <>",
        style: TextStyle(
          // --- ⭐️ MODIFIED: Theme grey color ---
          color: textTheme.bodySmall?.color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ],
  );
}

// --- ⭐️⭐️ FIX: Naya widget jo InstrumentProvider ko listen karega ⭐️⭐️ ---
class _WatchlistStockItem extends StatelessWidget {
  final String token;
  final bool isEditMode;
  final bool isSelected;

  const _WatchlistStockItem({
    required this.token,
    required this.isEditMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    // This Consumer *will* rebuild when prices change
    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // Get the latest instrument data
        final instrument = provider.getInstrumentByToken(token);
        if (instrument == null) {
          // Stock might have been removed, show a placeholder
          return Container(
            height: 60,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Loading $token...",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          );
        }

        // --- ⭐️ Theme se colors lo ---
        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);

        return Container(
          // --- ⭐️ MODIFIED: Theme selection color ---
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : theme.scaffoldBackgroundColor,
          child: Row(
            children: [
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 8.0,
                  ), // Padding add kiya
                  child: IgnorePointer(
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (val) {},
                      // --- ⭐️ MODIFIED: Theme primary color ---
                      activeColor: colorScheme.primary,
                      // --- ⭐️ MODIFIED: Theme border color ---
                      side: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
              Expanded(
                child: StockCard(
                  instrument: instrument,
                  onTap: null, // Handled by parent InkWell
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
