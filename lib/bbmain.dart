import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'providers/portfolio_provider.dart'; // Import the new provider

void main() {
  runApp(
    // Wrap the entire app in a ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => PortfolioProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockly',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
