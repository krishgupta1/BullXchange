import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/widgets/shimmer_loading.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ViewAllPage extends StatefulWidget {
  const ViewAllPage({super.key});

  @override
  State<ViewAllPage> createState() => _ViewAllPageState();
}

class _ViewAllPageState extends State<ViewAllPage> {
  List<Instrument> allStocks = [];
  List<Instrument> filteredStocks = [];
  List<Instrument> displayedStocks = [];
  final int batchSize = 50;
  bool isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InstrumentProvider>(context, listen: false);

    // --- (Stock filtering logic unchanged) ---
    allStocks = provider.allNSEStocks.where((stock) {
      final baseSymbol = stock.symbol.replaceAll('-EQ', '');
      final lowerCaseName = stock.name.toLowerCase();
      if (baseSymbol.contains(RegExp(r'[0-9]'))) return false;
      const excludedKeywords = [
        'etf',
        'bees',
        'nifty',
        'gold',
        'bond',
        'debenture',
        'pref',
        'index',
      ];
      if (excludedKeywords.any((keyword) => lowerCaseName.contains(keyword))) {
        return false;
      }
      if (baseSymbol.length < 3 || baseSymbol.length > 12) return false;
      if (!RegExp(r'^[A-Z]+$').hasMatch(baseSymbol)) return false;
      return true;
    }).toList();
    filteredStocks = allStocks;
    _loadMoreItems();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !isLoadingMore &&
          displayedStocks.length < filteredStocks.length) {
        _loadMoreItems();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _loadMoreItems() {
    if (isLoadingMore) return;
    setState(() => isLoadingMore = true);
    final currentLength = displayedStocks.length;
    final moreItems = filteredStocks
        .skip(currentLength)
        .take(batchSize)
        .toList();

    if (moreItems.isNotEmpty) {
      displayedStocks.addAll(moreItems);
    }

    final provider = Provider.of<InstrumentProvider>(context, listen: false);
    provider.fetchLiveDataFor(moreItems);
    provider.fetchChartDataFor(moreItems);

    setState(() => isLoadingMore = false);
  }

  void _searchStocks(String query) {
    final results = allStocks.where((stock) {
      final symbol = stock.symbol.toLowerCase();
      final name = stock.name.toLowerCase();
      final searchQuery = query.toLowerCase();
      return symbol.contains(searchQuery) || name.contains(searchQuery);
    }).toList();
    setState(() {
      filteredStocks = results;
      displayedStocks.clear();
    });
    _loadMoreItems();
  }

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- ⭐️ MODIFIED: Background color theme se ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // --- ⭐️ MODIFIED: Standard BackButton use kiya (theme-aware) ---
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
          // Color theme_provider.dart se aa jayega (kBrandPink)
        ),
        title: Text(
          "Select Stocks",
          // --- ⭐️ MODIFIED: Style ab AppTheme se aa raha hai ---
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        // --- ⭐️ MODIFIED: Background aur elevation AppTheme se aa raha hai ---
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            // --- ⭐️ MODIFIED: context pass kiya ---
            child: _buildSearchBar(context),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRect(
              child: Consumer<InstrumentProvider>(
                builder: (context, provider, child) {
                  if (allStocks.isEmpty) {
                    // --- ⭐️ MODIFIED: context pass kiya ---
                    return _buildShimmerLoadingList(context);
                  }

                  if (filteredStocks.isEmpty) {
                    return Center(
                      child: Text(
                        "No stocks found.",
                        // --- ⭐️ MODIFIED: Theme text color ---
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    );
                  }

                  return Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      controller: _scrollController,
                      itemCount:
                          displayedStocks.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= displayedStocks.length) {
                          // --- ⭐️ MODIFIED: context pass kiya ---
                          return _buildLoadMoreShimmer(context);
                        }
                        final instrument = displayedStocks[index];
                        return StockCard(
                          // Yeh already theme-aware hai
                          instrument: instrument,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StockDetailPage(instrument: instrument),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return TextField(
      controller: searchController,
      onChanged: _searchStocks,
      // --- ⭐️ MODIFIED: Theme text color ---
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: "Search company, stocks...",
        // --- ⭐️ MODIFIED: Theme hint color ---
        hintStyle: TextStyle(color: textTheme.bodySmall?.color, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 12.0),
          // --- ⭐️ MODIFIED: Theme accent color ---
          child: Icon(Icons.circle, color: colorScheme.secondary, size: 16),
        ),
        filled: true,
        // --- ⭐️ MODIFIED: Theme surface color (Not white) ---
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          // --- ⭐️ MODIFIED: Theme border color ---
          borderSide: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          // --- ⭐️ MODIFIED: Theme border color ---
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// SHIMMER HELPER WIDGETS (Theme-Aware)
// ----------------------------------------------------

Widget _buildShimmerLoadingList(BuildContext context) {
  // --- ⭐️ Theme se colors lo ---
  final theme = Theme.of(context);

  return Shimmer.fromColors(
    // --- ⭐️ MODIFIED: Theme-aware shimmer ---
    baseColor: theme.brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[800]!,
    highlightColor: theme.brightness == Brightness.light
        ? Colors.grey[100]!
        : Colors.grey[700]!,
    child: ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return const StockShimmerItem(); // Yeh bhi theme-aware hona chahiye
      },
    ),
  );
}

Widget _buildLoadMoreShimmer(BuildContext context) {
  // --- ⭐️ Theme se colors lo ---
  final theme = Theme.of(context);

  return Shimmer.fromColors(
    // --- ⭐️ MODIFIED: Theme-aware shimmer ---
    baseColor: theme.brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[800]!,
    highlightColor: theme.brightness == Brightness.light
        ? Colors.grey[100]!
        : Colors.grey[700]!,
    child: const Column(children: [StockShimmerItem(), StockShimmerItem()]),
  );
}
