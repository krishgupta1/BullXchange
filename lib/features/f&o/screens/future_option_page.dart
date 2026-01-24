import 'package:bullxchange/features/f&o/screens/future_option_explore_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_orders_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_position_page.dart';
import 'package:bullxchange/features/f&o/screens/future_option_transactions.dart';
import 'package:bullxchange/features/stock_market/widgets/action_tab_bar.dart';
import 'package:bullxchange/features/stock_market/widgets/index_card.dart';
import 'package:bullxchange/features/stock_market/widgets/main_page_header.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/utils/responsive_helper.dart';

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

  // --- Refresh Index Data ---
  Future<void> _refreshIndexData(InstrumentProvider provider) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text("Refreshing index data..."),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Refresh NIFTY data
      final indices = [
        if (provider.nifty50 != null) provider.nifty50!,
        if (provider.bankNifty != null) provider.bankNifty!,
      ];
      
      if (indices.isNotEmpty) {
        await provider.fetchLiveDataFor(indices);
      }
      
      // Hide loading and show success
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Index data refreshed!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to refresh: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        if (!mounted) return;
        setState(() => _uid = user.uid);
      }

      // 1. Check Display Name from Auth
      if (user != null &&
          user.displayName != null &&
          user.displayName!.trim().isNotEmpty) {
        if (!mounted) return;
        setState(() => _userName = user.displayName);
        return;
      }

      // 2. Fallback to Firestore Profile
      if (_uid != null) {
        final profile = await UserService().readUserProfile(_uid!);
        if (!mounted) return; // Safety check after async

        if (profile != null && profile.name.trim().isNotEmpty) {
          setState(() => _userName = profile.name);
        }
      }
    } catch (_) {
      // Fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Initialize responsive helper
    ResponsiveHelper.init(context, BoxConstraints.tightFor(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
    ));

    return Consumer<InstrumentProvider>(
      builder: (context, provider, child) {
        // Scaffold automatically uses Theme.of(context).scaffoldBackgroundColor
        // This ensures seamless Light/Dark mode switching.
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: ResponsiveHelper.smallSpacing),
                  MainPageHeader(
                    userName: _userName,
                    defaultUserName: 'User',
                    welcomeMessage: 'Welcome to BullXchange',
                    onProfileTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  SizedBox(height: ResponsiveHelper.sectionSpacing * 1.25),

                  // ✨ Index Cards with Refresh
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _refreshIndexData(provider),
                          child: IndexCard(
                            instrument: provider.nifty50,
                            title: "NIFTY 50",
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.horizontalPadding),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _refreshIndexData(provider),
                          child: IndexCard(
                            instrument: provider.bankNifty,
                            title: "BANK NIFTY",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.itemSpacing * 1.25),

                  // ✨ Action Tabs
                  ActionTabBar(
                    labels: const [
                      "Explore",
                      "Position",
                      "Orders",
                      "Transactions",
                    ],
                    selectedIndex: _selectedActionIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _selectedActionIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // ✨ Content Area
                  Expanded(
                    child: IndexedStack(
                      index: _selectedActionIndex,
                      children: const [
                        FutureOptionExplorePage(),
                        FnoPositionsPage(),
                        FutureOptionOrdersPage(),
                        FnoTransactionsPage(),
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
}
