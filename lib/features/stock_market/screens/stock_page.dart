import 'package:bullxchange/features/stock_market/screens/holdings_page.dart';
import 'package:bullxchange/features/stock_market/screens/order_page.dart';
import 'package:bullxchange/features/stock_market/screens/position_page.dart';
import 'package:bullxchange/features/stock_market/screens/watchlist_page.dart';
import 'package:flutter/material.dart';
import 'explore_page.dart'; // Import the new explore page

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  // 1. STATE MANAGEMENT
  // This variable will keep track of which page to show.
  // 0 = Explore, 1 = Holdings, 2 = Position, 3 = Orders, 4 = Watchlist
  int _selectedActionIndex = 0;

  // This list holds the different page widgets to be displayed.
  final List<Widget> _actionPages = [
    const ExplorePage(),
    const HoldingsPage(),
    const PositionPage(),
    const OrderPage(),
    const WatchlistPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- COMMON UI WIDGETS ---
            // These widgets will always be visible on the StockPage.
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 30),
            _buildIndexCards(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),

            // --- DYNAMIC CONTENT AREA ---
            // This is where the content will change based on the selected button.
            IndexedStack(index: _selectedActionIndex, children: _actionPages),
          ],
        ),
      ),
    );
  }

  // No changes to _buildHeader() and _buildIndexCard()
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
              "Hi, Kitsbase!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              "Welcome to Tradebase",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
      ],
    );
  }

  Widget _buildIndexCards() {
    return Row(
      children: [
        Expanded(
          child: _buildIndexCard(
            name: "NIFTY 50",
            value: "2202.42",
            change: "-27.40 (0.11%)",
            changeColor: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildIndexCard(
            name: "BANK NIFTY",
            value: "2202.42",
            change: "-27.40 (0.11%)",
            changeColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildIndexCard({
    required String name,
    required String value,
    required String change,
    required Color changeColor,
  }) {
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
            "\$$value",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            change,
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

  // 2. UPDATED ACTION BUTTONS
  // Now includes tap handling to update the state.
  Widget _buildActionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionButton("Explore", 0),
          _buildActionButton("Holdings", 1),
          _buildActionButton("Position", 2),
          _buildActionButton("Orders", 3),
          _buildActionButton("Watchlist", 4),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, int index) {
    bool isSelected = _selectedActionIndex == index;
    return GestureDetector(
      onTap: () {
        // When a button is tapped, update the state to the new index.
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
