// lib/features/f&o/screens/future_option_page.dart

import 'package:bullxchange/features/f&o/screens/future_option_explore_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_orders_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_position_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_watchlist_page.dart';
import 'package:bullxchange/features/stock_market/widgets/action_tab_bar.dart';
import 'package:bullxchange/features/stock_market/widgets/index_card.dart';
import 'package:bullxchange/features/stock_market/widgets/main_page_header.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FutureOptionPage extends StatefulWidget {
  const FutureOptionPage({super.key});

  @override
  State<FutureOptionPage> createState() => _FutureOptionPageState();
}

class _FutureOptionPageState extends State<FutureOptionPage>
    with AutomaticKeepAliveClientMixin {
  // Page State
  int _selectedActionIndex = 0;
  String? _userName;
  String? _uid;

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
    super.build(context);

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ✨ 2. USE THE NEW MainPageHeader WIDGET
                  MainPageHeader(
                    userName: _userName,
                    defaultUserName: 'Kitsbase',
                    welcomeMessage:
                        'Welcome to BullXchange', // Corrected message
                    actions: [
                      IconButton(
                        onPressed: () {
                          // TODO: Implement options menu
                        },
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ✨ 3. USE THE NEW IndexCard WIDGET
                  Row(
                    children: [
                      Expanded(
                        child: IndexCard(
                          instrument: provider.nifty50,
                          title: "NIFTY 50",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: IndexCard(
                          instrument: provider.bankNifty,
                          title: "BANK NIFTY",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✨ 4. USE THE NEW ActionTabBar WIDGET
                  ActionTabBar(
                    labels: const [
                      "Explore",
                      "Position",
                      "Orders",
                      "Watchlist",
                    ],
                    selectedIndex: _selectedActionIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _selectedActionIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

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

  // ✨ 5. ALL _build... METHODS HAVE BEEN REMOVED
}
