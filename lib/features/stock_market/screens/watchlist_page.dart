import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/screens/view_all_page.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Ideally, import your Instrument model to use it in Selector types
// import 'package:bullxchange/models/instrument_model.dart';

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
  UserProfileDataModel? _lastProfile;

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

    final colorScheme = Theme.of(context).colorScheme;

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            child: Text('Remove', style: TextStyle(color: colorScheme.error)),
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

    // We limit StreamBuilder scope to just the header/count and the list area so
    // that frequent user-profile updates (e.g. watchlist changes) do not rebuild
    // unrelated parts of the page. This ensures we only reload data, not the whole UI.

    final provider = Provider.of<InstrumentProvider>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small StreamBuilder only for header count and edit/delete state
              StreamBuilder<UserProfileDataModel?>(
                stream: _userService.streamUserProfile(uid!),
                builder: (context, snapshot) {
                  final int count = (snapshot.hasData && snapshot.data != null)
                      ? snapshot.data!.watchlist.length
                      : 0;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildWatchlistHeader(
                        count,
                        context,
                        _isEditMode,
                        _toggleEditMode,
                        _deleteSelectedStocks,
                        _selectedTokens.isNotEmpty,
                      ),
                      const SizedBox(height: 16),
                      _buildSortHeader(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: theme.dividerColor.withOpacity(0.1),
        ),

        // List area StreamBuilder: only this subtree rebuilds on profile updates
        StreamBuilder<UserProfileDataModel?>(
          stream: _userService.streamUserProfile(uid!),
          builder: (context, snapshot) {
            // Keep the last known profile so brief disconnects or reconnects
            // do not force a full-page loading state.
            if (snapshot.hasError) {
              // Show a small inline error but attempt to use cached data below
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Watchlist stream error: ${snapshot.error}',
                      ),
                    ),
                  );
                }
              });
            }

            if (snapshot.hasData && snapshot.data != null) {
              _lastProfile = snapshot.data;
            }

            final userProfile = snapshot.data ?? _lastProfile;

            if (userProfile == null) {
              // If we have no data at all, show an empty-state rather than a
              // fullscreen spinner to avoid the feeling of a page reload.
              return const Center(child: _EmptyState());
            }

            final userWatchlistTokens = userProfile.watchlist;

            // Filter the stocks once based on user's list
            final watchlistStocks = provider.allNSEStocks
                .where((stock) => userWatchlistTokens.contains(stock.token))
                .toList();

            if (watchlistStocks.isEmpty && !_isEditMode) {
              return const Center(child: _EmptyState());
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: watchlistStocks.length,
              addAutomaticKeepAlives: false,
              itemBuilder: (context, index) {
                final instrumentToken = watchlistStocks[index].token;
                final isSelected = _selectedTokens.contains(instrumentToken);

                return InkWell(
                  onTap: () {
                    if (_isEditMode) {
                      _toggleSelection(instrumentToken);
                    } else {
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
                  child: _WatchlistStockItem(
                    key: ValueKey(instrumentToken),
                    token: instrumentToken,
                    isEditMode: _isEditMode,
                    isSelected: isSelected,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
          color: textTheme.bodySmall?.color,
        ),
        const SizedBox(height: 16),
        Text(
          "Your Watchlist is Empty",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add stocks to your watchlist to track them easily.",
          style: TextStyle(color: textTheme.bodySmall?.color),
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
  final colorScheme = Theme.of(context).colorScheme;

  return Row(
    children: [
      Text(
        isEditMode ? "Select Stocks" : "$stockCount stocks",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      const Spacer(),
      if (isEditMode) ...[
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: hasSelection ? colorScheme.error : Colors.grey,
          ),
          onPressed: hasSelection ? onDeleteSelected : null,
        ),
        IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: onToggleEdit,
        ),
      ] else ...[
        IconButton(
          icon: Icon(Icons.add_box_outlined, color: colorScheme.onSurface),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ViewAllPage()),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
          onPressed: onToggleEdit,
        ),
      ],
    ],
  );
}

Widget _buildSortHeader(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

  return Row(
    children: [
      TextButton.icon(
        icon: Icon(Icons.sort, color: textTheme.bodySmall?.color, size: 18),
        label: Text(
          "Sort",
          style: TextStyle(color: textTheme.bodySmall?.color),
        ),
        onPressed: () {},
      ),
      const Spacer(),
      Text(
        "Mkt price / 1D <>",
        style: TextStyle(
          color: textTheme.bodySmall?.color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ],
  );
}

// --- OPTIMIZED WIDGET: Uses Selector instead of Consumer ---
class _WatchlistStockItem extends StatelessWidget {
  final String token;
  final bool isEditMode;
  final bool isSelected;

  const _WatchlistStockItem({
    super.key,
    required this.token,
    required this.isEditMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Selector ensures this widget ONLY rebuilds if THIS SPECIFIC token's data changes.
    // Replace 'Instrument' with your actual model class name if different.
    return Selector<InstrumentProvider, dynamic>(
      // Changed to dynamic to avoid type errors if I don't know your exact model class, change to Instrument?
      selector: (context, provider) => provider.getInstrumentByToken(token),
      shouldRebuild: (previous, next) {
        // If your provider returns a NEW object instance every update, standard equality is fine:
        return previous != next;

        // If your provider updates properties inside the SAME object, use this instead:
        // return previous?.lastPrice != next?.lastPrice || previous?.changePercent != next?.changePercent;
      },
      builder: (context, instrument, child) {
        if (instrument == null) {
          return Container(
            height: 60,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Loading...",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          );
        }

        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);

        return Container(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : theme.scaffoldBackgroundColor,
          child: Row(
            children: [
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: IgnorePointer(
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (val) {},
                      activeColor: colorScheme.primary,
                      side: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
              Expanded(
                // StockCard is now isolated and won't rebuild unnecessarily
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
