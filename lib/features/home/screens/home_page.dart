// lib/features/home/screens/home_page.dart

import 'package:bullxchange/features/home/widgets/bottom_navigation.dart';
import 'package:bullxchange/features/stock_market/screens/stock_page.dart';
import 'package:flutter/material.dart';

// --- 1. IMPORT THE REQUIRED PACKAGES ---
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

  // --- 2. ADD SERVICE AND UID ---
  final UserService _userService = UserService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // --- 3. YOUR WIDGET LIST IS NOW UPDATED ---
  final List<Widget> _widgetOptions = <Widget>[
    const StockPage(),
    const Center(child: Text('F&O', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Portfolio Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('AI Stats Page', style: TextStyle(fontSize: 24))),
    // ✨ ADDED: 5th page to match the nav bar
    const Center(child: Text('Account Page', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4. ADDED A CHECK FOR UID
    if (uid == null) {
      // This is a safety check
      return const Scaffold(
        body: Center(child: Text("Error: User not logged in.")),
      );
    }

    // 5. WRAPPED THE SCAFFOLD WITH THE STREAMPROVIDER
    //    This is the only change you need to make.
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
