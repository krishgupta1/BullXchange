import 'package:bullxchange/features/stock_market/screens/holdings_page.dart';
import 'package:bullxchange/features/stock_market/screens/order_page.dart';
import 'package:bullxchange/features/stock_market/screens/position_page.dart';
import 'package:bullxchange/features/stock_market/screens/watchlist_page.dart';
import 'package:flutter/material.dart';
import 'explore_page.dart';

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
    // ✨ FIX 1: Removed SingleChildScrollView.
    // The main layout is now a Column that fills the screen.
    return SafeArea(
      child: Padding(
        // Use Padding instead of padding on a ScrollView.
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- STATIC TOP CONTENT ---
            // These widgets will always be visible.
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 30),
            _buildIndexCards(),
            const SizedBox(height: 20),
            _buildActionButtons(),

            // --- DYNAMIC CONTENT AREA ---
            // ✨ FIX 2: Wrap IndexedStack with Expanded.
            // This tells the IndexedStack to fill all remaining vertical space in the Column.
            // This gives it a finite, bounded height, which solves the error.
            Expanded(
              child: IndexedStack(
                index: _selectedActionIndex,
                children: [
                  const ExplorePage(),
                  const HoldingsPage(),
                  const PositionPage(),
                  const OrderPage(),
                  const WatchlistPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No changes needed for your builder methods (_buildHeader, _buildIndexCards, etc.)
  // They are perfectly fine.

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

  Widget _buildActionButtons() {
    // This is fine, but make sure your pages are created for each button.
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
