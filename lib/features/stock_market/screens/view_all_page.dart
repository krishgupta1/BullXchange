import 'dart:math';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InstrumentProvider>(context, listen: false);
    allStocks = provider.allNSEStocks;
    filteredStocks = allStocks;
    _loadMoreItems();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 300 &&
          !isLoadingMore &&
          displayedStocks.length < filteredStocks.length) {
        _loadMoreItems();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
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
            child: Consumer<InstrumentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && displayedStocks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (filteredStocks.isEmpty) {
                  return const Center(child: Text("No stocks found."));
                }
                // ✨ WRAP WITH SCROLLBAR WIDGET ✨
                return Scrollbar(
                  child: ListView.builder(
                    // ✨ ADD BOUNCING PHYSICS FOR SMOOTHER SCROLLING ✨
                    physics: const BouncingScrollPhysics(),
                    // ✨ THIS LINE FIXES THE TOOLTIP OVERLAP ✨
                    clipBehavior: Clip.none,

                    controller: scrollController,
                    itemCount: displayedStocks.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= displayedStocks.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final instrument = displayedStocks[index];
                      return _buildStockItem(instrument);
                    },
                  ),
                );
              },
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

// Helper widgets below do not need changes.
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

Widget _buildLogoContainer(String name) {
  if (name.toLowerCase().contains('google'))
    return SvgPicture.network(
      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
      width: 40,
      height: 40,
    );
  if (name.toLowerCase().contains('microsoft'))
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/512px-Microsoft_logo.svg.png',
      width: 40,
      height: 40,
    );
  if (name.toLowerCase().contains('nike'))
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png',
      width: 40,
      height: 40,
      color: Colors.black,
    );
  final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
  final color = Colors.primaries[name.hashCode % Colors.primaries.length];
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildStockItem(Instrument instrument) {
  final ltp = instrument.liveData["ltp"]?.toString() ?? "--";
  final percentChange =
      num.tryParse(
        instrument.liveData["percentChange"].toString(),
      )?.toDouble() ??
      0.0;
  final changeColor = percentChange >= 0 ? const Color(0xFF1EAB58) : Colors.red;
  final List<double> chartData = _createSimulatedChartData(instrument);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    child: Row(
      children: [
        _buildLogoContainer(instrument.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instrument.symbol,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

Widget _buildMiniChart(List<double> data, Color color) {
  return LineChart(
    LineChartData(
      clipData: FlClipData.none(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.black87,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                '₹${barSpot.y.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
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
