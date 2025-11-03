import 'package:bullxchange/features/home/screens/home_page.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the widget that "provides" the InstrumentProvider to the whole app.
    return ChangeNotifierProvider(
      // The 'create' function builds the instance of your provider.
      // This happens only once.
      create: (context) => InstrumentProvider(),
      child: MaterialApp(
        title: 'TradeSim AI',
        theme: ThemeData(
          fontFamily: 'EudoxusSans',
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        // Your app's home screen.
        home: HomePage(),
      ),
    );
  }
}
