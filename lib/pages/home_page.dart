import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart'; 
import 'dart:ui';
import 'dart:async';

import 'package:final_project_att1/services/alpha_vantage_service.dart';
import 'package:final_project_att1/models/quote_model.dart';
import 'package:final_project_att1/providers/portfolio_provider.dart';

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
  Timer? _timer;

  Map<String, Quote?> _quotes = {
    'AAPL': null, 'SPY': null, 'QQQ': null, 'DIA': null, 'IWM': null
  };

  @override
  void initState() {
    super.initState();
    _updateAllQuotes(); 
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) => _updateAllQuotes());
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  Future<void> _updateAllQuotes() async {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    final List<Future<Quote>> futures = _quotes.keys.map((symbol) => AlphaVantageService.getQuote(symbol)).toList();
    final List<Quote> results = await Future.wait(futures);

    if (mounted) {
      setState(() {
        for (var quote in results) {
          _quotes[quote.symbol] = quote;
          portfolioProvider.updateLivePrice(quote.symbol, quote.currentPrice);
        }
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => _getNavPage(index)));
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
              const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/images/profile_pic.png')),
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
            IconButton(icon: const Icon(FeatherIcons.bell, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()))),
            IconButton(icon: const Icon(FeatherIcons.search, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()))),
          ],
        )
      ],
    );
  }
  
  Widget _buildPortfolioCard() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final gainLoss = portfolio.dailyGainLoss;
        final gainLossPercent = portfolio.dailyGainLossPercent;
        final quote = _quotes['AAPL'];

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioPage())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stocks Value', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('\$${portfolio.totalStockMarketValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${gainLoss >= 0 ? '+' : ''}\$${gainLoss.toStringAsFixed(2)} (${gainLossPercent.toStringAsFixed(2)}%) Today',
                        style: TextStyle(color: gainLoss >= 0 ? Colors.green : Colors.red, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                quote == null 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : _buildTrendingCard(quote),
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
                _buildIndexCard('S&P 500', 'SPY', _quotes['SPY']),
                const SizedBox(width: 16),
                _buildIndexCard('Nasdaq 100', 'QQQ', _quotes['QQQ']),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildIndexCard('Dow Jones', 'DIA', _quotes['DIA']),
                const SizedBox(width: 16),
                _buildIndexCard('Russell 2000', 'IWM', _quotes['IWM']),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndexCard(String name, String symbol, Quote? quote) {
    return Expanded(
      child: quote == null
        ? Container(height: 150, decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)), child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)))
        : GestureDetector(
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
          )
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

