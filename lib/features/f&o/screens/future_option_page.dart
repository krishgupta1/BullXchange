
import 'package:bullxchange/features/f&o/screens/future_option_explore_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_orders_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_position_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_watchlist_page.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✨ 1. ADDED IMPORTS FOR YOUR NEW PAGES

class FutureOptionPage extends StatefulWidget {
  const FutureOptionPage({super.key});

  @override
  State<FutureOptionPage> createState() => _FutureOptionPageState();
}

// ✨ 2. ADDED MIXIN TO KEEP TAB STATE ALIVE
class _FutureOptionPageState extends State<FutureOptionPage>
    with AutomaticKeepAliveClientMixin {
  // Page State
  int _selectedActionIndex = 0;
  String? _userName;
  String? _uid;

  // ✨ 3. ADDED wantKeepAlive
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() => _uid = user.uid);
      }

      if (user != null &&
          user.displayName != null &&
          user.displayName!.trim().isNotEmpty) {
        setState(() => _userName = user.displayName);
        return;
      }

      if (_uid != null) {
        final profile = await UserService().readUserProfile(_uid!);
        if (profile != null && profile.name.trim().isNotEmpty) {
          if (!mounted) return;
          setState(() => _userName = profile.name);
          return;
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  // ----------------------------------------------------
  // BUILD METHOD
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ✨ 4. Added super.build(context) for the mixin
    super.build(context);

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        //
        // ✨ ----- MAJOR LAYOUT FIX ----- ✨
        //
        // Replaced ListView with a Column + Expanded.
        // This keeps the header/tabs fixed at the top
        // and gives the IndexedStack a finite height.
        //
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column( // ✨ WAS ListView
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildIndexCards(provider.nifty50, provider.bankNifty),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 20),

                  // ✨ This Expanded widget is the fix ✨
                  Expanded(
                    child: IndexedStack(
                      index: _selectedActionIndex,
                      children: const [
                        FutureOptionExplorePage(),
                        FutureOptionPositionPage(),
                        FutureOptionOrdersPage(),
                        FutureOptionWatchlistPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // WIDGET BUILDER METHODS
  // ----------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFEAE2FF),
          child: Icon(Icons.person, color: Color(0xFF7A4DFF), size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${_userName ?? 'Kitsbase'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Text(
              'Welcome to Tradebase',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            // TODO: Implement options menu
          },
          icon: const Icon(Icons.more_horiz),
        ),
      ],
    );
  }

  Widget _buildIndexCards(Instrument? nifty50, Instrument? bankNifty) {
    return Row(
      children: [
        Expanded(child: _buildIndexCard(instrument: nifty50, name: "NIFTY 50")),
        const SizedBox(width: 16),
        Expanded(child: _buildIndexCard(instrument: bankNifty, name: "BANK NIFTY")),
      ],
    );
  }

  Widget _buildIndexCard(
      {required Instrument? instrument, required String name}) {
    final value = instrument?.liveData["ltp"]?.toStringAsFixed(2) ?? "0.00";
    final netChange =
        instrument?.liveData["netChange"]?.toStringAsFixed(2) ?? "0.00";
    final percentChange =
        instrument?.liveData["percentChange"]?.toStringAsFixed(2) ?? "0.00";

    final double changeValue = num.tryParse(netChange)?.toDouble() ?? 0.0;
    final changeColor = changeValue.isNegative ? Colors.red : Colors.green;

    final changeText = "$netChange($percentChange%)";

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
            value != "0.00" ? "₹$value" : "...",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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