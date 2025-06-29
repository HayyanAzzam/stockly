import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stockly/pages/welcome_page.dart';
import 'package:stockly/pages/auth_page.dart';
import 'package:stockly/pages/main_page.dart';
import 'package:stockly/pages/news_and_stock_page.dart';
import 'package:stockly/pages/portfolio_page.dart';
import 'package:stockly/pages/pro_version_page.dart';
import 'package:stockly/pages/stock_detail_page.dart';

// The entry point of the application
void main() {
  runApp(const StocklyApp());
}

class StocklyApp extends StatelessWidget {
  const StocklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sets the status bar style for the app
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return MaterialApp(
      title: 'Stockly',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF121212),
        brightness: Brightness.dark,
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF22c55e),
          unselectedItemColor: Colors.white54,
        ),
      ),
      debugShowCheckedModeBanner: false,
      // The first page to be displayed when the app starts
      home: const WelcomePage(),
      // Named routes for navigating between pages
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const MainPage(),
        '/news': (context) => const NewsAndStockPage(),
        '/portfolio':(context) => const PortfolioPage(),
        '/pro':(context) => const ProVersionPage(),
        '/stock_detail':(context) => const StockDetailPage(stockId: 'AAPL'),
      },
    );
  }
}
