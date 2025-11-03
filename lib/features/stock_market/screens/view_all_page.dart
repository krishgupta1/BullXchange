import 'dart:math';
import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/screens/stock_page.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/auth/widgets/app_back_button.dart';
import 'package:bullxchange/features/stock_market/widgets/mini_chart.dart';
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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StockPage()),
          ),
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
                  // Initial Shimmer for full list only if all stocks are being loaded for the first time
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
                          // Show Load More Shimmer
                          return _buildLoadMoreShimmer();
                        }
                        final instrument = displayedStocks[index];
                        return _buildStockItem(context, instrument);
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
// SHIMMER HELPER WIDGETS
// ----------------------------------------------------

Widget _buildShimmerStockItem() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 12,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 4),
              ),
              Container(width: 150, height: 12, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 50,
              height: 12,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 4),
            ),
            Container(width: 40, height: 12, color: Colors.white),
          ],
        ),
      ],
    ),
  );
}

Widget _buildShimmerLoadingList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildShimmerStockItem();
      },
    ),
  );
}

Widget _buildLoadMoreShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Column(
      children: [_buildShimmerStockItem(), _buildShimmerStockItem()],
    ),
  );
}

// ----------------------------------------------------
// 🚀 MODIFIED: STOCK ITEM WIDGET
// ----------------------------------------------------

Widget _buildStockItem(BuildContext context, Instrument instrument) {
  // We rely on the SmartLogo's internal state for logo shimmer.
  final ltp = instrument.liveData["ltp"]?.toString() ?? "--";
  final percentChange =
      num.tryParse(
        instrument.liveData["percentChange"].toString(),
      )?.toDouble() ??
      0.0;
  final changeColor = percentChange >= 0 ? const Color(0xFF1EAB58) : Colors.red;
  final List<double> chartData = _createSimulatedChartData(instrument);

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockDetailPage(instrument: instrument),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          SmartLogo(instrument: instrument, radius: 0),
          // ⭐ SmartLogo will now handle its own shimmer internally.
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

          // ✅ FIX: MiniChart is now displayed directly without conditional shimmer.
          SizedBox(
            width: 80,
            height: 40,
            child: MiniChart(data: chartData, color: changeColor),
          ),

          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹$ltp",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
    ),
  );
}

// ----------------------------------------------------
// SIMULATED CHART DATA FUNCTION (Unchanged)
// ----------------------------------------------------

List<double> _createSimulatedChartData(Instrument instrument) {
  final ltp =
      num.tryParse(instrument.liveData['ltp'].toString())?.toDouble() ?? 0.0;
  final netChange =
      num.tryParse(instrument.liveData['netChange'].toString())?.toDouble() ??
      0.0;
  // If data is not available (ltp is 0.0), this returns a flat line.
  if (ltp == 0.0) return List<double>.generate(15, (_) => 1.0);
  final startPrice = ltp - netChange;
  final points = <double>[];
  final random = Random(instrument.symbol.hashCode);
  for (int i = 0; i < 15; i++) {
    if (i == 14) {
      points.add(ltp);
    } else {
      double progress = i / 14.0;
      double priceAtProgress = startPrice + (netChange * progress);
      double variance = ltp * 0.01 * (random.nextDouble() - 0.5);
      points.add(priceAtProgress + variance);
    }
  }
  return points;
}
