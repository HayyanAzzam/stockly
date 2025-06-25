import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'dart:ui';
import 'dart:async';

import 'package:final_project_att1/services/alpha_vantage_service.dart';
import 'package:final_project_att1/models/quote_model.dart';
import 'package:final_project_att1/providers/portfolio_provider.dart'; // Import Portfolio Provider

import 'portfolio_page.dart';
import 'stock_detail_page.dart';
import 'notifications_page.dart';
import 'search_page.dart';
import 'watchlist_page.dart';
import 'news_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;

  late Future<Quote> _appleQuoteFuture;
  late Future<Quote> _sp500QuoteFuture;
  late Future<Quote> _nasdaqQuoteFuture;
  late Future<Quote> _dowJonesQuoteFuture;
  late Future<Quote> _russellQuoteFuture;

  @override
  void initState() {
    super.initState();
    _appleQuoteFuture = AlphaVantageService.getQuote('AAPL');
    _sp500QuoteFuture = AlphaVantageService.getQuote('SPY'); 
    _nasdaqQuoteFuture = AlphaVantageService.getQuote('QQQ');
    _dowJonesQuoteFuture = AlphaVantageService.getQuote('DIA');
    _russellQuoteFuture = AlphaVantageService.getQuote('IWM'); 
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => _getNavPage(index)),
    );
  }

  Widget _getNavPage(int index) {
    switch (index) {
      case 0: return const PortfolioPage();
      case 1: return const WatchlistPage();
      case 2: return const HomePage();
      case 3: return const NewsPage();
      case 4: return const ProfilePage();
      default: return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildPortfolioCard(),
                const SizedBox(height: 30),
                _buildMarketIndices(),
                const SizedBox(height: 30),
                _buildRecommendedInvestments(),
                const SizedBox(height: 30),
                _buildStocksSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioPage())),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage('assets/images/profile_pic.png'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Fadi Abbara', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(FeatherIcons.bell, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
            ),
            IconButton(
              icon: const Icon(FeatherIcons.search, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage())),
            ),
          ],
        )
      ],
    );
  }
  
  Widget _buildPortfolioCard() {
    // Use a Consumer widget to listen to changes in PortfolioProvider
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioPage())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portfolio Value', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 4),
                    // Display the cash balance from the provider
                    Text(
                      '\$${portfolio.cashBalance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // This would need more complex logic to calculate daily change
                    const Text('+0.00% Today', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
                FutureBuilder<Quote>(
                  future: _appleQuoteFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(width: 100, height: 80, child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)));
                    } else if (snapshot.hasError || (snapshot.hasData && snapshot.data!.error != null)) {
                      return const SizedBox(width: 100, height: 80, child: Center(child: Text('Error', style: TextStyle(color: Colors.red))));
                    } else if (snapshot.hasData) {
                      return _buildTrendingCard(snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingCard(Quote quote) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StockDetailPage(stockSymbol: 'AAPL'))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: quote.isUp ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Trending', style: TextStyle(color: Colors.grey[400])),
            const Text('Apple', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('\$${quote.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            Text('${quote.percentChange.toStringAsFixed(2)}%', style: TextStyle(color: quote.isUp ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketIndices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Market Indices', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                _buildIndexCardFuture('S&P 500', 'SPY', _sp500QuoteFuture),
                const SizedBox(width: 16),
                _buildIndexCardFuture('Nasdaq 100', 'QQQ', _nasdaqQuoteFuture),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildIndexCardFuture('Dow Jones', 'DIA', _dowJonesQuoteFuture),
                const SizedBox(width: 16),
                _buildIndexCardFuture('Russell 2000', 'IWM', _russellQuoteFuture),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndexCardFuture(String name, String symbol, Future<Quote> future) {
    return Expanded(
      child: FutureBuilder<Quote>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 150,
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
              child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)),
            );
          } else if (snapshot.hasError) {
             return _marketIndexErrorCard(name, "Network Error");
          } else if (snapshot.hasData) {
            final quote = snapshot.data!;
            if (quote.error != null) {
              final message = quote.error!.contains("high API call frequency") ? "API Limit Reached" : "Data Unavailable";
              return _marketIndexErrorCard(name, message);
            }
            return _marketIndexCard(name, symbol, quote);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _marketIndexCard(String name, String symbol, Quote quote) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StockDetailPage(stockSymbol: symbol))),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: quote.isUp ? Colors.green.withOpacity(0.8) : Colors.red, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(quote.isUp ? FeatherIcons.trendingUp : FeatherIcons.trendingDown, color: Colors.white),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(quote.currentPrice.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text('${quote.percentChange.toStringAsFixed(2)}%', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _marketIndexErrorCard(String name, String message) {
     return Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center,)),
          ],
        ),
      );
  }
  
  Widget _buildRecommendedInvestments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended investments', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(child: _blurryCard(isUp: false)),
                    const SizedBox(width: 16),
                    Expanded(child: _blurryCard(isUp: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _blurryCard(isUp: true)),
                  ],
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(color: Colors.black.withOpacity(0.1)),
                ),
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FeatherIcons.lock, color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text('Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _blurryCard({required bool isUp}) {
    return Container(
      decoration: BoxDecoration(color: isUp ? Colors.green.withOpacity(0.6) : Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: Center(child: Icon(isUp ? FeatherIcons.trendingUp : FeatherIcons.trendingDown, color: Colors.white54)),
    );
  }

  Widget _buildStocksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stocks', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          children: [
            _stockLogo('AAPL', 'assets/images/apple.png'),
            _stockLogo('GOOGL', 'assets/images/google.png'),
            _stockLogo('AMZN', 'assets/images/amazon.png'),
            _stockLogo('NVDA', 'assets/images/nvidia.png'),
            _stockLogo('MSFT', 'assets/images/microsoft.png'),
            _stockLogo('BTC-USD', 'assets/images/bitcoin.png'),
          ],
        )
      ],
    );
  }

  Widget _stockLogo(String symbol, String assetPath) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StockDetailPage(stockSymbol: symbol))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15)),
        child: Image.asset(
          assetPath,
          errorBuilder: (context, error, stackTrace) => Center(child: Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(FeatherIcons.pieChart), label: 'Portfolio'),
        BottomNavigationBarItem(icon: Icon(FeatherIcons.list), label: 'Watch list'),
        BottomNavigationBarItem(icon: Icon(FeatherIcons.barChart2), label: 'Markets'),
        BottomNavigationBarItem(icon: Icon(FeatherIcons.globe), label: 'News'),
        BottomNavigationBarItem(icon: Icon(FeatherIcons.user), label: 'Profile'),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Colors.grey[900],
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[600],
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
    );
  }
}

