import 'dart:math';
import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/widgets/smart_logo.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/features/auth/widgets/app_back_button.dart';

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
    displayedStocks.addAll(moreItems);
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
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        title: const Text(
          "Select Stocks",
          style: TextStyle(fontWeight: FontWeight.bold),
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
                  if (provider.isLoading && displayedStocks.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
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
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final instrument = displayedStocks[index];
                        // MODIFIED: Pass context to _buildStockItem
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
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 12.0),
          child: Icon(Icons.circle, color: Color(0xFFDB1B57), size: 16),
        ),
        suffixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(Icons.mic, color: Colors.grey),
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

// MODIFIED: Function now accepts BuildContext
Widget _buildStockItem(BuildContext context, Instrument instrument) {
  final ltp = instrument.liveData["ltp"]?.toString() ?? "--";
  final percentChange =
      num.tryParse(
        instrument.liveData["percentChange"].toString(),
      )?.toDouble() ??
      0.0;
  final changeColor = percentChange >= 0 ? const Color(0xFF1EAB58) : Colors.red;
  final List<double> chartData = _createSimulatedChartData(instrument);

  // WRAPPED with InkWell for tap functionality
  return InkWell(
    onTap: () {
      // ADDED: Navigation logic
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
          SmartLogo(instrument: instrument),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrument.symbol.replaceAll('-EQ', ''), // Clean up symbol
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
            width: 80,
            height: 40,
            child: _buildMiniChart(chartData, changeColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹$ltp",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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

List<double> _createSimulatedChartData(Instrument instrument) {
  final ltp =
      num.tryParse(instrument.liveData['ltp'].toString())?.toDouble() ?? 0.0;
  final netChange =
      num.tryParse(instrument.liveData['netChange'].toString())?.toDouble() ??
      0.0;
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

Widget _buildMiniChart(List<double> data, Color color) {
  return LineChart(
    LineChartData(
      clipData: FlClipData.none(),
      lineTouchData: LineTouchData(
        enabled: false, // Disable touch events on the mini chart
      ),
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList(),
          isCurved: true,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    ),
  );
}
