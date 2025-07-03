import 'package:flutter/material.dart';

class PortfolioProvider extends ChangeNotifier {
  double availableCash = 100000.0;
  double portfolioValue = 0.0;

  // For graphing: list of (timestamp, value)
  final List<Map<String, dynamic>> valueHistory = [];

  // Owned stocks: symbol -> {shares, avgBuyPrice}
  final Map<String, Map<String, dynamic>> ownedStocks = {};

  // This map will store the last known price for each owned stock.
  final Map<String, double> _lastKnownPrices = {};

  PortfolioProvider() {
    // Record initial value for graph
    valueHistory.add({'timestamp': DateTime.now(), 'value': portfolioValue});
  }

  void applyExchangeRateToCash(double rate) {
    availableCash = availableCash * rate;
    notifyListeners();
  }

  void buyStock(
    String symbol,
    double price,
    double shares, {
    String? name,
    String? logo,
  }) {
    if (shares <= 0) return;
    final cost = price * shares;
    if (cost > availableCash) return;
    availableCash -= cost;
    if (ownedStocks.containsKey(symbol)) {
      final prevShares = ownedStocks[symbol]!['shares'] as double;
      final prevAvg = ownedStocks[symbol]!['avgBuyPrice'] as double;
      final newShares = prevShares + shares;
      final newAvg = ((prevShares * prevAvg) + (shares * price)) / newShares;
      ownedStocks[symbol]!['shares'] = newShares;
      ownedStocks[symbol]!['avgBuyPrice'] = newAvg;
      ownedStocks[symbol]!['name'] = name ?? ownedStocks[symbol]!['name'];
      ownedStocks[symbol]!['logo'] = logo ?? ownedStocks[symbol]!['logo'];
    } else {
      ownedStocks[symbol] = {
        'shares': shares,
        'avgBuyPrice': price,
        'name': name ?? symbol,
        'logo': logo,
      };
    }
    _lastKnownPrices[symbol] = price;
    updatePortfolioValue();
    notifyListeners();
  }

  void sellStock(String symbol, double price, double shares) {
    if (!ownedStocks.containsKey(symbol) || shares <= 0) return;
    final prevShares = ownedStocks[symbol]!['shares'] as double;
    if (shares > prevShares) return;
    availableCash += price * shares;
    final newShares = prevShares - shares;
    if (newShares > 0) {
      ownedStocks[symbol]!['shares'] = newShares;
    } else {
      ownedStocks.remove(symbol);
      _lastKnownPrices.remove(symbol); // Remove price when stock is sold out
    }
    _lastKnownPrices[symbol] = price;
    updatePortfolioValue();
    notifyListeners();
  }

  void updatePortfolioValue([Map<String, double>? newPrices]) {
    if (newPrices != null) {
      _lastKnownPrices.addAll(newPrices);
    }
    double total = 0.0;
    ownedStocks.forEach((symbol, data) {
      final shares = data['shares'] as double;
      // Use the last known price for calculation.
      final price = _lastKnownPrices[symbol] ?? 0.0;
      final assetValue = shares * price;
      total += assetValue;
      data['value'] = assetValue; // Store the calculated value for the UI
    });
    portfolioValue = total;
    valueHistory.add({'timestamp': DateTime.now(), 'value': portfolioValue});
    notifyListeners();
  }

  void updatePortfolioValueFromMarket(List<Map<String, dynamic>> marketStocks) {
    final Map<String, double> prices = {
      for (final stock in marketStocks)
        stock['symbol']: (stock['price'] as double),
    };
    updatePortfolioValue(prices);
  }

  void resetPortfolio() {
    availableCash = 100000.0;
    portfolioValue = 0.0;
    ownedStocks.clear();
    valueHistory.clear();
    valueHistory.add({'timestamp': DateTime.now(), 'value': portfolioValue});
    notifyListeners();
  }
}
