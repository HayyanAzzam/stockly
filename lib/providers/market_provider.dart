import 'package:flutter/material.dart';
import '../services/finnhub_service.dart';
import 'portfolio_provider.dart';
import 'package:provider/provider.dart';

class MarketProvider extends ChangeNotifier {
  final FinnhubService _service = FinnhubService();
  List<Map<String, dynamic>> marketIndices = [];
  List<Map<String, dynamic>> trendingStocks = [];
  List<Map<String, dynamic>> marketStocks = [];
  bool isLoading = false;

  Future<void> fetchMarketData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      // Fetch market indices and trending stocks in parallel
      final futures = await Future.wait([
        _service.fetchMarketIndices(context),
        _service.fetchTrendingStocks(context),
      ]);

      marketIndices = futures[0];
      trendingStocks = futures[1];

      // Update portfolio with latest prices
      final portfolioProvider = Provider.of<PortfolioProvider>(
        context,
        listen: false,
      );

      // Combine all symbols for portfolio updates
      final Set<String> allSymbols = {
        ...portfolioProvider.ownedStocks.keys,
        ...marketIndices.map((e) => e['symbol']),
        ...trendingStocks.map((e) => e['symbol']),
      };

      final quotes = await _service.fetchQuotes(allSymbols.toList(), context);
      final List<Map<String, dynamic>> stocks = [];

      for (final symbol in allSymbols) {
        final quote = quotes[symbol];
        if (quote != null) {
          final currentPrice = (quote['c'] as num?)?.toDouble() ?? 0.0;
          final prevClose = (quote['pc'] as num?)?.toDouble() ?? 0.0;
          final change = currentPrice - prevClose;
          final isUp = change >= 0;

          // Find existing data from indices or trending stocks
          Map<String, dynamic>? existingData;
          existingData = marketIndices.firstWhere(
            (e) => e['symbol'] == symbol,
            orElse: () => {},
          );
          if (existingData.isEmpty) {
            existingData = trendingStocks.firstWhere(
              (e) => e['symbol'] == symbol,
              orElse: () => {},
            );
          }

          stocks.add({
            'symbol': symbol,
            'name': existingData['name'] ?? symbol,
            'logo': existingData['logo'],
            'price': currentPrice,
            'change': change,
            'isUp': isUp,
          });
        }
      }

      marketStocks = stocks;
    } catch (e) {
      print('Error fetching market data: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // Legacy method for backward compatibility
  Future<void> fetchMarketStocks(BuildContext context) async {
    await fetchMarketData(context);
  }
}
