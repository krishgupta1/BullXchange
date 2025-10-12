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

  // A list of widgets to display for each tab.
  static const List<Widget> _widgetOptions = <Widget>[
    StockPage(),
    Center(child: Text('F&O Page', style: TextStyle(fontSize: 24))),
    Center(child: Text('Portfolio Page', style: TextStyle(fontSize: 24))),
    Center(child: Text('AI Stats Page', style: TextStyle(fontSize: 24))),
  ];

  // The function to update the selected index.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body displays the widget based on the selected index.
      body: _widgetOptions.elementAt(_selectedIndex),

      // We call the separate bottom navigation bar widget here.
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
