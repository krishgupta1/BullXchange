import 'package:flutter/material.dart';

// --- ⭐️ F&O WATCHLIST PAGE (STATEFUL) ---
// (Mimics the edit/delete functionality of your WatchListPage)
class FutureOptionWatchlistPage extends StatefulWidget {
  const FutureOptionWatchlistPage({super.key});

  @override
  State<FutureOptionWatchlistPage> createState() =>
      _FutureOptionWatchlistPageState();
}

class _FutureOptionWatchlistPageState extends State<FutureOptionWatchlistPage> {
  bool _isEditMode = false;
  final Set<String> _selectedTokens = {}; // Use the symbol as the unique token

  // --- Static data for the list ---
  final List<Map<String, dynamic>> _fnoWatchlist = [
    {
      'symbol': 'NIFTY 28NOV25 24500 CE',
      'ltp': 142.75,
      'change': 22.25,
      'changePercent': 18.46,
      'logoLetter': 'N',
      'logoColor': Colors.blue.shade700,
    },
    {
      'symbol': 'BANKNIFTY 28NOV25 51000 PE',
      'ltp': 280.40,
      'change': -29.80,
      'changePercent': -9.61,
      'logoLetter': 'B',
      'logoColor': Colors.red.shade700,
    },
    {
      'symbol': 'FINNIFTY 25NOV25 22000 CE',
      'ltp': 68.30,
      'change': 3.20,
      'changePercent': 4.91,
      'logoLetter': 'F',
      'logoColor': Colors.green.shade700,
    },
    {
      'symbol': 'RELIANCE 28NOV25 3000 FUT',
      'ltp': 3012.50,
      'change': 15.10,
      'changePercent': 0.50,
      'logoLetter': 'R',
      'logoColor': Colors.blue.shade900,
    },
  ];

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

  void _deleteSelectedItems() async {
    if (_selectedTokens.isEmpty) return;

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Instruments?'),
        content: Text(
          'Are you sure you want to remove ${_selectedTokens.length} instrument(s) from your F&O watchlist?',
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

    // --- Static demo: just show a snackbar and exit edit mode ---
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${_selectedTokens.length} F&O instruments.'),
        backgroundColor: Colors.green,
      ),
    );
    _toggleEditMode();
  }

  @override
  Widget build(BuildContext context) {
    // Set to 'false' to see the empty state
    bool hasWatchlist = true;

    if (!hasWatchlist && !_isEditMode) {
      return const Center(child: _EmptyState());
    }

    // --- ⭐️ Structure copied from your WatchListPage ---
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildWatchlistHeader(
                _fnoWatchlist.length,
                context,
                _isEditMode,
                _toggleEditMode,
                _deleteSelectedItems,
                _selectedTokens.isNotEmpty,
              ),
              const SizedBox(height: 16),
              _buildSortHeader(), // Re-used from your code
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _fnoWatchlist.length,
            itemBuilder: (context, index) {
              final instrument = _fnoWatchlist[index];
              final token = instrument['symbol'] as String;
              final isSelected = _selectedTokens.contains(token);

              return InkWell(
                onTap: () {
                  if (_isEditMode) {
                    _toggleSelection(token);
                  } else {
                    // --- Static action: Show SnackBar ---
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Tapped on $token')));
                  }
                },
                child: _buildFnoItem(
                  instrument: instrument,
                  isEditMode: _isEditMode,
                  isSelected: isSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- ⭐️ EMPTY STATE ---
// (Copied and text modified for F&O)
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "F&O Watchlist is Empty",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Add options or futures to your watchlist to track them.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// --- ⭐️ WATCHLIST HEADER ---
// (Copied and "Add" button removed)
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
        isEditMode ? "Select Instruments" : "$stockCount instruments",
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
        // --- "Add" button removed ---
        // (Adding F&O is complex, often involves an option chain)
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onToggleEdit,
        ),
      ],
    ],
  );
}

// --- ⭐️ SORT HEADER ---
// (Copied directly from your WatchListPage)
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

// --- ⭐️ F&O ITEM WIDGET ---
// (Mimics your _buildStockItem + StockCard layout)
Widget _buildFnoItem({
  required Map<String, dynamic> instrument,
  bool isEditMode = false,
  bool isSelected = false,
}) {
  final String symbol = instrument['symbol'];
  final double ltp = instrument['ltp'];
  final double change = instrument['change'];
  final double changePercent = instrument['changePercent'];
  final Color color = change >= 0 ? Colors.green : Colors.red;
  final String sign = change >= 0 ? '+' : '';

  return Container(
    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
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
        Expanded(
          // --- This layout mimics your StockCard ---
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                _buildLogoContainer(
                  instrument['logoLetter'],
                  color: instrument['logoColor'],
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NSE F&O', // Static exchange
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${ltp.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sign${change.toStringAsFixed(2)} ($sign${changePercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// --- Helper for the logo ---
Widget _buildLogoContainer(String name, {double radius = 20, Color? color}) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";
  final logoColor =
      color ?? Colors.primaries[name.hashCode % Colors.primaries.length];
  return Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(color: logoColor, shape: BoxShape.circle),
    child: Center(
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
