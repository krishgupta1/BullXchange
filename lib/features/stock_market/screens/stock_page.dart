import 'package:bullxchange/features/stock_market/screens/explore_page.dart';
import 'package:bullxchange/features/stock_market/screens/holdings_page.dart';
import 'package:bullxchange/features/stock_market/screens/order_page.dart';
import 'package:bullxchange/features/stock_market/screens/position_page.dart';
import 'package:bullxchange/features/stock_market/screens/watchlist_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _selectedActionIndex = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // ✨ FIX: Show a loading spinner for the entire page
        // until the initial data fetch is complete.
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show an error message if something went wrong
        if (provider.errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${provider.errorMessage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        // Once loaded, build the main UI
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // All content is now part of one scrollable list
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildIndexCards(provider.nifty50, provider.bankNifty),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 20), // Add spacing
                // The content of the selected tab
                IndexedStack(
                  index: _selectedActionIndex,
                  children: [
                    ExplorePage(),
                    const HoldingsPage(),
                    const PositionPage(),
                    const OrderPage(),
                    const WatchlistPage(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // All your helper methods below this point remain exactly the same.

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFEAE2FF),
          child: Icon(Icons.person, color: Color(0xFF7A4DFF), size: 28),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, User!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              "Welcome to Bullxchange",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
      ],
    );
  }

  Widget _buildIndexCards(Instrument? nifty50, Instrument? bankNifty) {
    return Row(
      children: [
        Expanded(child: _buildIndexCard(instrument: nifty50)),
        const SizedBox(width: 16),
        Expanded(child: _buildIndexCard(instrument: bankNifty)),
      ],
    );
  }

  Widget _buildIndexCard({required Instrument? instrument}) {
    final name =
        instrument?.name.toUpperCase().replaceFirst("NIFTY ", "") ??
        "LOADING...";
    final value = instrument?.liveData["ltp"]?.toString() ?? "--";
    final netChange = instrument?.liveData["netChange"]?.toString() ?? "0";
    final percentChange =
        instrument?.liveData["percentChange"]?.toString() ?? "0";
    final double changeValue = num.tryParse(netChange)?.toDouble() ?? 0.0;
    final changeColor = changeValue >= 0 ? Colors.green : Colors.red;
    final changeText = "$netChange ($percentChange%)";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value != "--" ? "₹$value" : value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              color: changeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttonLabels = [
      "Explore",
      "Holdings",
      "Position",
      "Orders",
      "Watchlist",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(buttonLabels.length, (index) {
          return _buildActionButton(buttonLabels[index], index);
        }),
      ),
    );
  }

  Widget _buildActionButton(String text, int index) {
    bool isSelected = _selectedActionIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActionIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDB1B57) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
