import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/screens/view_all_page.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Added Sort Types
enum SortType {
  priceLowToHigh,
  priceHighToLow,
  alphabeticalAZ,
  alphabeticalZA,
  percentLowToHigh,
  percentHighToLow,
}

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

  // Added Sort State
  SortType _currentSort = SortType.priceLowToHigh;

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

  // Allow external widgets to update sorting via a safe method
  void updateSort(SortType value) {
    setState(() {
      _currentSort = value;
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

    final provider = Provider.of<InstrumentProvider>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<UserProfileDataModel?>(
                stream: _userService.streamUserProfile(uid!),
                builder: (context, snapshot) {
                  final int count = (snapshot.hasData && snapshot.data != null)
                      ? snapshot.data!.watchlist.length
                      : 0;

                  return Column(
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
                      _buildSortHeader(context), // Updated
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

        StreamBuilder<UserProfileDataModel?>(
          stream: _userService.streamUserProfile(uid!),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
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
              return const Center(child: _EmptyState());
            }

            final userWatchlistTokens = userProfile.watchlist;

            final watchlistStocks = provider.allNSEStocks
                .where((stock) => userWatchlistTokens.contains(stock.token))
                .toList();

            // ---------------------- SORTING LOGIC ADDED ----------------------
            watchlistStocks.sort((a, b) {
              final aPrice = (a.liveData['ltp'] ?? 0).toDouble();
              final bPrice = (b.liveData['ltp'] ?? 0).toDouble();
              final aPct = (a.liveData['percentChange'] ?? 0).toDouble();
              final bPct = (b.liveData['percentChange'] ?? 0).toDouble();

              switch (_currentSort) {
                case SortType.priceLowToHigh:
                  return aPrice.compareTo(bPrice);
                case SortType.priceHighToLow:
                  return bPrice.compareTo(aPrice);
                case SortType.alphabeticalAZ:
                  return a.name.compareTo(b.name);
                case SortType.alphabeticalZA:
                  return b.name.compareTo(a.name);
                case SortType.percentLowToHigh:
                  return aPct.compareTo(bPct);
                case SortType.percentHighToLow:
                  return bPct.compareTo(aPct);
              }
            });
            // ----------------------------------------------------------------

            if (watchlistStocks.isEmpty && !_isEditMode) {
              return const Center(child: _EmptyState());
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: watchlistStocks.length,
              itemBuilder: (context, index) {
                final inst = watchlistStocks[index];
                final isSelected = _selectedTokens.contains(inst.token);

                return InkWell(
                  onTap: () {
                    if (_isEditMode) {
                      _toggleSelection(inst.token);
                    } else {
                      final instrument = provider.getInstrumentByToken(
                        inst.token,
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
                    key: ValueKey(inst.token),
                    token: inst.token,
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
            fontSize: 10,
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
          fontSize: 10,
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
            // ----- CHANGED FROM pushReplacement TO push -----
            // This stacks ViewAllPage ON TOP of WatchListPage
            // instead of destroying WatchListPage.
            Navigator.push(
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
      PopupMenuButton<SortType>(
        onSelected: (value) {
          final state = context.findAncestorStateOfType<_WatchListPageState>();
          state?.updateSort(value);
        },
        child: Row(
          children: [
            Icon(Icons.sort, color: textTheme.bodySmall?.color, size: 18),
            const SizedBox(width: 4),
            Text("Sort", style: TextStyle(color: textTheme.bodySmall?.color)),
          ],
        ),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: SortType.priceLowToHigh,
            child: Text("Price: Low → High"),
          ),
          PopupMenuItem(
            value: SortType.priceHighToLow,
            child: Text("Price: High → Low"),
          ),
          PopupMenuItem(
            value: SortType.alphabeticalAZ,
            child: Text("Alphabetical: A → Z"),
          ),
          PopupMenuItem(
            value: SortType.alphabeticalZA,
            child: Text("Alphabetical: Z → A"),
          ),
          PopupMenuItem(
            value: SortType.percentLowToHigh,
            child: Text("% Change: Low → High"),
          ),
          PopupMenuItem(
            value: SortType.percentHighToLow,
            child: Text("% Change: High → Low"),
          ),
        ],
      ),
      const Spacer(),
      Text(
        "Mkt price / 1D <>",
        style: TextStyle(
          color: textTheme.bodySmall?.color,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    ],
  );
}

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
    return Selector<InstrumentProvider, dynamic>(
      selector: (context, provider) => provider.getInstrumentByToken(token),
      builder: (context, instrument, _) {
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

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

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
                      onChanged: (_) {},
                      side: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
              Expanded(
                child: StockCard(
                  instrument: instrument,
                  onTap: null,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
