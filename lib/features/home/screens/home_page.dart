import 'package:bullxchange/features/home/widgets/bottom_navigation.dart';
import 'package:bullxchange/features/stock_market/screens/stock_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // ✨ FIX 1: Remove `static const` to allow for stateful instances of widgets.
  final List<Widget> _widgetOptions = <Widget>[
    const StockPage(), // Assuming StockPage can be a const constructor
    const Center(child: Text('F&O', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Portfolio Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('AI Stats Page', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ✨ FIX 2: Use IndexedStack to preserve the state of each tab.
      // This widget keeps all children mounted but only shows the one at the current index.
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
