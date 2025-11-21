import 'package:bullxchange/features/account/screens/account_page.dart';
import 'package:bullxchange/features/f&o/screens/Future_option_page.dart';
import 'package:bullxchange/features/home/Navigation/side_menu.dart';
import 'package:bullxchange/features/home/widgets/bottom_navigation.dart';
import 'package:bullxchange/features/portfolio/screens/portfolio_page.dart';
import 'package:bullxchange/features/stock_market/screens/stock_page.dart';
import 'package:flutter/material.dart';

// --- IMPORTS ---
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:bullxchange/models/order_model.dart'; // Import OrderModel
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final UserService _userService = UserService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _widgetOptions = <Widget>[
    const StockPage(),
    const FutureOptionPage(),
    const PortfolioPage(),
    Builder(
      builder: (context) {
        return Center(
          child: Text(
            'AI Stats Page',
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    ),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (uid == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text(
            "Error: User not logged in.",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    // --- ⭐️ CHANGE TO MULTI PROVIDER ⭐️ ---
    // This allows you to provide BOTH the User Profile AND the Orders List
    return MultiProvider(
      providers: [
        // 1. User Profile Stream
        StreamProvider<UserProfileDataModel?>(
          create: (_) => _userService.streamUserProfile(uid!),
          initialData: null,
        ),

        // 2. ⭐️ ORDERS STREAM (THE FIX) ⭐️
        // We use the function you created in UserService which filters by 'userId'
        StreamProvider<List<OrderModel>>(
          create: (_) => _userService.streamOpenOrders(uid!),
          initialData: const [],
          catchError: (context, error) {
            // This prevents the "Exception caught by Provider" red screen
            // It will just return an empty list if permission fails
            print("Error streaming orders: $error");
            return [];
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: const SideMenu(),
        body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
