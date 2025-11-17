import 'package:bullxchange/features/account/screens/account_page.dart';
import 'package:bullxchange/features/f&o/screens/Future_option_page.dart';
import 'package:bullxchange/features/home/Navigation/side_menu.dart';
import 'package:bullxchange/features/home/widgets/bottom_navigation.dart';
import 'package:bullxchange/features/stock_market/screens/stock_page.dart';
import 'package:flutter/material.dart';

import 'package:bullxchange/models/user_profile_data_model.dart';
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
    // Builder use kiya taaki context mil sake
    Builder(
      builder: (context) {
        return Center(
          child: Text(
            'Portfolio Page',
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).colorScheme.onSurface, // Theme text
            ),
          ),
        );
      },
    ),
    Builder(
      builder: (context) {
        return Center(
          child: Text(
            'AI Stats Page',
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).colorScheme.onSurface, // Theme text
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

    return StreamProvider<UserProfileDataModel?>(
      create: (_) => _userService.streamUserProfile(uid!),
      initialData: null,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        // --- ⭐️⭐️ 2. DRAWER KO YAHAN ADD KARO ⭐️⭐️ ---
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
