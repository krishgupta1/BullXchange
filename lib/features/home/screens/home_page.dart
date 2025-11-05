import 'package:bullxchange/features/f&o/screens/Future_option_page.dart';
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

  // --- 2. UPDATE YOUR WIDGET LIST ---
  final List<Widget> _widgetOptions = <Widget>[
    const StockPage(),
    const FutureOptionPage(),
    const Center(child: Text('Portfolio Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('AI Stats Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Account Page', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Error: User not logged in.")),
      );
    }

    return StreamProvider<UserProfileDataModel?>(
      create: (_) => _userService.streamUserProfile(uid!),
      initialData: null,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}