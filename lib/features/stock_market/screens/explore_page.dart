import 'package:bullxchange/provider/market_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Infinite scroll listener
    _scrollController.addListener(() {
      final provider = context.read<StocksProvider>();
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !provider.isLoadingMore) {
        context.read<StocksProvider>().loadMoreItems();
        // Load next batch
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StocksProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.displayedStocks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader("Top Stocks"),
            const SizedBox(height: 10),

            // Stocks List
            ...provider.displayedStocks
                .map((stock) => _buildStockItem(stock))
                .toList(),

            const SizedBox(height: 20),
            _buildSectionHeader("Tools"),
            const SizedBox(height: 20),
            _buildToolsGrid(),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ... inside _ExplorePageState (in explore_page.dart)

  Widget _buildStockItem(dynamic stock) {
    // stock = Instrument
    final double latestPrice = stock.lastPrices;
    final double changePercentage = stock.changePercent;

    // Use the changePercentage getter directly
    final changeColor = changePercentage >= 0 ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // ... (Code for CircleAvatar, Expanded Column)

          // Mini Chart
          SizedBox(
            width: 80,
            height: 40,
            // ⭐️ FIX: lastPrices एक double है, List नहीं। MiniChart के लिए
            // आपको एक List<double> चाहिए। मैंने यहां एक डमी लिस्ट पास की है
            // (असली डेटा के लिए आपको API से 5-day या intraday history fetch करनी होगी)।
            child: _buildMiniChart([10.0, 15.0, 12.0, 18.0, 16.0]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ⭐️ FIX: Use latestPrice (यानी lastPrices) ⭐️
              Text(
                "\₹${latestPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${changePercentage.toStringAsFixed(2)}%",
                style: TextStyle(color: changeColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(List<double> data) {
    return LineChart(
      LineChartData(
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
            color: Colors.blueAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildToolItem(Icons.campaign, "IPO", const Color(0xFFE3D9FF)),
        ),
        Expanded(
          child: _buildToolItem(
            Icons.newspaper,
            "NEWS",
            const Color(0xFFD9EFFF),
          ),
        ),
        Expanded(
          child: _buildToolItem(
            Icons.broadcast_on_home,
            "COMMUNITY",
            const Color(0xFFD9EFFF),
          ),
        ),
        Expanded(
          child: _buildToolItem(Icons.star, "EVENT", const Color(0xFFFFDDC4)),
        ),
        Expanded(
          child: _buildToolItem(
            Icons.calculate,
            "CHARGES",
            const Color(0xFFD0F2E3),
          ),
        ),
      ],
    );
  }

  Widget _buildToolItem(IconData icon, String label, Color bgColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black87, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey[700], fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
