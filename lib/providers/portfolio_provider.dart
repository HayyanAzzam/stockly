import 'package:flutter/material.dart';
import '../screens/home_page.dart';

class PortfolioProvider extends ChangeNotifier {
  final Map<String, double> _availableCash = {};
  final Map<String, double> _portfolioValue = {};
  final Map<String, List<Map<String, dynamic>>> _valueHistory = {};
  final Map<String, Map<String, Map<String, dynamic>>> _ownedStocks = {};
  final Map<String, Map<String, double>> _lastKnownPrices = {};

  String get _user => UserSession.email ?? 'guest';

  double get availableCash => _availableCash[_user] ?? 100000.0;
  double get portfolioValue => _portfolioValue[_user] ?? 0.0;
  List<Map<String, dynamic>> get valueHistory =>
      _valueHistory[_user] ??
      [
        {'timestamp': DateTime.now(), 'value': 0.0},
      ];
  Map<String, Map<String, dynamic>> get ownedStocks =>
      _ownedStocks[_user] ?? {};

  PortfolioProvider() {
    // Record initial value for graph
    valueHistory.add({'timestamp': DateTime.now(), 'value': portfolioValue});
  }

  void _initUser() {
    _availableCash.putIfAbsent(_user, () => 100000.0);
    _portfolioValue.putIfAbsent(_user, () => 0.0);
    _valueHistory.putIfAbsent(
      _user,
      () => [
        {'timestamp': DateTime.now(), 'value': 0.0},
      ],
    );
    _ownedStocks.putIfAbsent(_user, () => {});
    _lastKnownPrices.putIfAbsent(_user, () => {});
  }

  void applyExchangeRateToCash(double rate) {
    _initUser();
    _availableCash[_user] = availableCash * rate;
    notifyListeners();
  }

  void buyStock(
    String symbol,
    double price,
    double shares, {
    String? name,
    String? logo,
  }) {
    _initUser();
    if (shares <= 0) return;
    final cost = price * shares;
    if (cost > availableCash) return;
    _availableCash[_user] = availableCash - cost;
    final stocks = _ownedStocks[_user]!;
    if (stocks.containsKey(symbol)) {
      final prevShares = stocks[symbol]!['shares'] as double;
      final prevAvg = stocks[symbol]!['avgBuyPrice'] as double;
      final newShares = prevShares + shares;
      final newAvg = ((prevShares * prevAvg) + (shares * price)) / newShares;
      stocks[symbol]!['shares'] = newShares;
      stocks[symbol]!['avgBuyPrice'] = newAvg;
      stocks[symbol]!['name'] = name ?? stocks[symbol]!['name'];
      stocks[symbol]!['logo'] = logo ?? stocks[symbol]!['logo'];
    } else {
      stocks[symbol] = {
        'shares': shares,
        'avgBuyPrice': price,
        'name': name ?? symbol,
        'logo': logo,
      };
    }
    _lastKnownPrices[_user]![symbol] = price;
    updatePortfolioValue();
    notifyListeners();
  }

  void sellStock(String symbol, double price, double shares) {
    _initUser();
    final stocks = _ownedStocks[_user]!;
    if (!stocks.containsKey(symbol) || shares <= 0) return;
    final prevShares = stocks[symbol]!['shares'] as double;
    if (shares > prevShares) return;
    _availableCash[_user] = availableCash + price * shares;
    final newShares = prevShares - shares;
    if (newShares > 0) {
      stocks[symbol]!['shares'] = newShares;
    } else {
      stocks.remove(symbol);
      _lastKnownPrices[_user]!.remove(symbol);
    }
    _lastKnownPrices[_user]![symbol] = price;
    updatePortfolioValue();
    notifyListeners();
  }

  void updatePortfolioValue([Map<String, double>? newPrices]) {
    _initUser();
    if (newPrices != null) {
      _lastKnownPrices[_user]!.addAll(newPrices);
    }
    double total = 0.0;
    final stocks = _ownedStocks[_user]!;
    stocks.forEach((symbol, data) {
      final shares = data['shares'] as double;
      final price = _lastKnownPrices[_user]![symbol] ?? 0.0;
      final assetValue = shares * price;
      total += assetValue;
      data['value'] = assetValue;
    });
    _portfolioValue[_user] = total;
    _valueHistory[_user]!.add({'timestamp': DateTime.now(), 'value': total});
    notifyListeners();
  }

  void updatePortfolioValueFromMarket(List<Map<String, dynamic>> marketStocks) {
    _initUser();
    final Map<String, double> prices = {
      for (final stock in marketStocks)
        stock['symbol']: (stock['price'] as double),
    };
    updatePortfolioValue(prices);
  }

  void resetPortfolio() {
    _availableCash[_user] = 100000.0;
    _portfolioValue[_user] = 0.0;
    _ownedStocks[_user]?.clear();
    _valueHistory[_user]?.clear();
    _valueHistory[_user]?.add({'timestamp': DateTime.now(), 'value': 0.0});
    notifyListeners();
  }
}
