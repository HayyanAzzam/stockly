import 'package:flutter/material.dart';
import '../services/finnhub_service.dart';
import 'portfolio_provider.dart';
import 'package:provider/provider.dart';

class MarketProvider extends ChangeNotifier {
  final FinnhubService _service = FinnhubService();
  // Optionally, keep a list of market indices for the home page
  final List<String> marketIndices = [
    'AAPL',
    'GOOGL',
    'MSFT',
    'AMZN',
    'NVDA',
    'TSLA',
  ];
  List<Map<String, dynamic>> marketStocks = [];
  bool isLoading = false;

  Future<void> fetchMarketStocks(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    final portfolioProvider = Provider.of<PortfolioProvider>(
      context,
      listen: false,
    );
    final Set<String> symbols = {
      ...portfolioProvider.ownedStocks.keys,
      ...marketIndices,
    };

    final quotes = await _service.fetchQuotes(symbols.toList(), context);
    final List<Map<String, dynamic>> stocks = [];

    for (final symbol in symbols) {
      final quote = quotes[symbol];
      final profile = await _service.fetchCompanyProfile(symbol);

      if (quote != null && profile != null) {
        final currentPrice = (quote['c'] as num?)?.toDouble() ?? 0.0;
        final prevClose = (quote['pc'] as num?)?.toDouble() ?? 0.0;
        stocks.add({
          'symbol': symbol,
          'name': profile['name'] ?? symbol,
          'logo': profile['logo'],
          'price': currentPrice,
          'change': currentPrice - prevClose,
          'isUp': (currentPrice - prevClose) >= 0,
        });
      }
    }

    marketStocks = stocks;
    isLoading = false;
    notifyListeners();
  }
}
