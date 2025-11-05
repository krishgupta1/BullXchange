// This is the full code for ViewAllPage.dart

// 1. REMOVE THIS IMPORT. YOU DO NOT NEED IT.
// import 'package:bullxchange/features/stock_market/screens/stock_page.dart';
import 'package:bullxchange/features/auth/widgets/app_back_button.dart';
import 'package:bullxchange/features/stock_market/widgets/shimmer_animation.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_list_item.dart';
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
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          // -------------------------------------------------
          // ✨ FIX 2: THIS MUST BE 'pop' TO "CLOSE" THIS PAGE
          // -------------------------------------------------
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Stocks",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRect(
              child: Consumer<InstrumentProvider>(
                builder: (context, provider, child) {
                  if (allStocks.isEmpty) {
                    return _buildShimmerLoadingList();
                  }

                  if (filteredStocks.isEmpty) {
                    return const Center(child: Text("No stocks found."));
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
                          return _buildLoadMoreShimmer();
                        }
                        final instrument = displayedStocks[index];
                        return StockListItem(instrument: instrument);
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

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      onChanged: _searchStocks,
      decoration: InputDecoration(
        hintText: "Search company, stocks...",
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 12.0),
          child: Icon(Icons.circle, color: Color(0xFFDB1B57), size: 16),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF908FEC), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF7A4DFF), width: 2),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// SHIMMER HELPER WIDGETS (Unchanged)
// ----------------------------------------------------

Widget _buildShimmerLoadingList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return const StockListItemShimmer();
      },
    ),
  );
}

Widget _buildLoadMoreShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Column(
      children: [const StockListItemShimmer(), const StockListItemShimmer()],
    ),
  );
}
