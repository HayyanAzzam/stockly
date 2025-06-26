import 'package:flutter/material.dart';
import '../services/portfolio_storage_service.dart';

// Represents a single stock holding in the portfolio
class Holding {
  final String symbol;
  double shares;
  double avgCost;

  Holding({required this.symbol, required this.shares, required this.avgCost});
  
  Map<String, dynamic> toJson() => {'symbol': symbol, 'shares': shares, 'avgCost': avgCost};

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'],
      shares: (json['shares'] as num).toDouble(),
      avgCost: (json['avgCost'] as num).toDouble(),
    );
  }
}

class PortfolioProvider with ChangeNotifier {
  double _cashBalance = 10000.00;
  List<Holding> _holdings = [];
  final PortfolioStorageService _storageService = PortfolioStorageService();
  
  // Stores the latest price for each owned stock.
  final Map<String, double> _livePrices = {};
  // Stores the price of each stock when the app session started.
  final Map<String, double> _initialSessionPrices = {};

  double get cashBalance => _cashBalance;
  List<Holding> get holdings => _holdings;
  // Public getter for other widgets to access initial prices.
  Map<String, double> get initialSessionPrices => _initialSessionPrices;
  
  // --- DYNAMIC CALCULATIONS ---

  // Calculates the total current market value of all stock holdings.
  double get totalStockMarketValue {
    if (_holdings.isEmpty) return 0.0;
    return _holdings.map((h) {
      final livePrice = _livePrices[h.symbol] ?? h.avgCost;
      return h.shares * livePrice;
    }).reduce((a, b) => a + b);
  }

  // The total value of the portfolio (cash + live stock value).
  double get totalPortfolioValue => _cashBalance + totalStockMarketValue;

  // Calculates the total value of holdings at the start of the session.
  double get totalInitialSessionValue {
      if (_holdings.isEmpty) return 0.0;
      return _holdings.map((h) {
          final initialPrice = _initialSessionPrices[h.symbol] ?? h.avgCost;
          return h.shares * initialPrice;
      }).reduce((a, b) => a + b);
  }

  // The total dollar gain or loss for the current session (Today's Change).
  double get dailyGainLoss => totalStockMarketValue - totalInitialSessionValue;
  
  // The total percentage gain or loss for the current session.
  double get dailyGainLossPercent {
      final initialValue = totalInitialSessionValue;
      if (initialValue == 0) return 0.0;
      return (dailyGainLoss / initialValue) * 100;
  }

  PortfolioProvider() {
    _loadPortfolio();
  }
  
  // Called by the UI to provide live price updates.
  void updateLivePrice(String symbol, double price) {
      // If this is the first price update for this symbol in this session, store it.
      if (!_initialSessionPrices.containsKey(symbol)) {
          _initialSessionPrices[symbol] = price;
      }

      if (_livePrices[symbol] != price) {
        _livePrices[symbol] = price;
        notifyListeners();
      }
  }
  
  Future<void> _loadPortfolio() async {
    final data = await _storageService.loadPortfolio();
    _cashBalance = data['cashBalance'];
    _holdings = (data['holdings'] as List).map((item) => Holding.fromJson(item)).toList();
    notifyListeners();
  }

  Future<void> _savePortfolio() async {
    await _storageService.savePortfolio(this);
  }

  void buyStock(String symbol, double shares, double price) {
    final cost = shares * price;
    if (_cashBalance >= cost) {
      _cashBalance -= cost;
      final existingHoldingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
      if (existingHoldingIndex != -1) {
        final h = _holdings[existingHoldingIndex];
        final newTotalShares = h.shares + shares;
        final newTotalCost = (h.shares * h.avgCost) + cost;
        h.avgCost = newTotalCost / newTotalShares;
        h.shares = newTotalShares;
      } else {
        _holdings.add(Holding(symbol: symbol, shares: shares, avgCost: price));
      }
      
      _savePortfolio();
      notifyListeners(); 
    }
  }

  void sellStock(String symbol, double shares, double price) {
    final idx = _holdings.indexWhere((h) => h.symbol == symbol);
    if (idx != -1) {
      final h = _holdings[idx];
      if (h.shares >= shares) {
        _cashBalance += shares * price;
        h.shares -= shares;
        if (h.shares < 0.0001) { 
          _holdings.removeAt(idx);
        }
        
        _savePortfolio();
        notifyListeners();
      }
    }
  }
  
  Map<String, dynamic> toJson() => {
    'cashBalance': _cashBalance,
    'holdings': _holdings.map((h) => h.toJson()).toList(),
  };
}

