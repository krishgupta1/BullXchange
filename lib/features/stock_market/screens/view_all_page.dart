import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/widgets/shimmer_loading.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colorScheme.onSurface,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          "Market Watch",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildSearchBar(context),
          ),
          Expanded(
            child: Consumer<InstrumentProvider>(
              builder: (context, provider, child) {
                if (allStocks.isEmpty) {
                  return _buildShimmerLoadingList(context);
                }

                if (filteredStocks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No stocks found",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayedStocks.length + (isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= displayedStocks.length) {
                      return _buildLoadMoreShimmer(context);
                    }
                    final instrument = displayedStocks[index];
                    return StockCard(
                      instrument: instrument,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockDetailPage(instrument: instrument),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: _searchStocks,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Search stocks...",
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.primary,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

Widget _buildShimmerLoadingList(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Shimmer.fromColors(
    baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
    highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
    child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const StockShimmerItem(),
    ),
  );
}

Widget _buildLoadMoreShimmer(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Shimmer.fromColors(
    baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
    highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
    child: const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: StockShimmerItem(),
    ),
  );
}
