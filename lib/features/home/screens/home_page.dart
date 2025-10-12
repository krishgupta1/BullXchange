import 'package:bullxchange/features/stock_market/screens/stock_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Step 2: Create a list of pages for each tab.
  // The first item is your StockPage, and the rest are placeholders.
  static const List<Widget> _widgetOptions = <Widget>[
    StockPage(), // This will be shown when Stocks (index 0) is selected
    Center(child: Text('F&O Page', style: TextStyle(fontSize: 24))),
    Center(child: Text('Portfolio Page', style: TextStyle(fontSize: 24))),
    Center(child: Text('AI Stats Page', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Step 3: Remove the AppBar and set the body to show the correct page.
      // The body will now display the widget from the list based on the selected tab.
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFDB1B57),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Stocks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'F&O',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI Stats',
          ),
        ],
      ),
    );
  }
}
