import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Using a relative path for robustness
import 'pages/home_page.dart'; 
import 'providers/portfolio_provider.dart';

void main() {
  runApp(
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
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomePage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

