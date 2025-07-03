import 'package:flutter/material.dart';
import '../services/finnhub_service.dart';

class MarketProvider extends ChangeNotifier {
  List<Map<String, dynamic>> marketStocks = [];

  final List<Map<String, String>> _marketSymbols = [
    {"name": "Apple Inc", "symbol": "AAPL"},
    {"name": "Boeing Co", "symbol": "BA"},
    {"name": "Tesla Inc", "symbol": "TSLA"},
    {"name": "Meta Platforms Inc", "symbol": "META"},
    {"name": "JPMorgan Chase & Co", "symbol": "JPM"},
    {"name": "Visa Inc", "symbol": "V"},
    {"name": "Walt Disney Co", "symbol": "DIS"},
  ];

  final FinnhubService _finnhubService = FinnhubService();

  MarketProvider() {
    // Don't call fetchMarketStocks here, require context
  }

  Future<void> fetchMarketStocks(BuildContext context) async {
    marketStocks = [];
    for (final stock in _marketSymbols) {
      final quote = await _finnhubService.fetchQuote(stock["symbol"]!, context);
      if (quote != null && quote["c"] != null && quote["pc"] != null) {
        final double current = (quote["c"] as num).toDouble();
        final double prevClose = (quote["pc"] as num).toDouble();
        marketStocks.add({
          "name": stock["name"],
          "symbol": stock["symbol"],
          "price": current,
          "isUp": current > prevClose,
        });
      }
    }
    notifyListeners();
  }

  Future<void> refreshMarketStocks(BuildContext context) async {
    await fetchMarketStocks(context);
  }
}
