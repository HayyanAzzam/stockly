import 'package:flutter/material.dart';

// Represents a single stock holding in the portfolio
class Holding {
  final String symbol;
  double shares;
  double avgCost;

  Holding({required this.symbol, required this.shares, required this.avgCost});
}

class PortfolioProvider with ChangeNotifier {
  // Initialize user with $10,000 cash and an empty portfolio
  double _cashBalance = 10000.00;
  final List<Holding> _holdings = [];

  double get cashBalance => _cashBalance;
  List<Holding> get holdings => _holdings;

  // Calculate total value of all stock holdings
  double get totalStockValue {
    // This is a simplified calculation. A real app would need live prices.
    // For now, we'll implement the full logic later.
    return 0.0;
  }

  // Calculate total portfolio value (cash + stocks)
  double get totalPortfolioValue => _cashBalance + totalStockValue;

  void buyStock(String symbol, double shares, double price) {
    final cost = shares * price;
    if (_cashBalance >= cost) {
      _cashBalance -= cost;

      // Check if user already owns this stock
      final existingHoldingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
      if (existingHoldingIndex != -1) {
        // Update existing holding
        final existingHolding = _holdings[existingHoldingIndex];
        final newTotalShares = existingHolding.shares + shares;
        final newTotalCost = (existingHolding.shares * existingHolding.avgCost) + cost;
        existingHolding.avgCost = newTotalCost / newTotalShares;
        existingHolding.shares = newTotalShares;
      } else {
        // Add new holding
        _holdings.add(Holding(symbol: symbol, shares: shares, avgCost: price));
      }
      
      // This tells any listening widgets to rebuild
      notifyListeners(); 
    } else {
      // Handle insufficient funds error in the UI
      print("Error: Insufficient funds to complete purchase.");
    }
  }

  void sellStock(String symbol, double shares, double price) {
    final existingHoldingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
    if (existingHoldingIndex != -1) {
      final existingHolding = _holdings[existingHoldingIndex];
      if (existingHolding.shares >= shares) {
        final proceeds = shares * price;
        _cashBalance += proceeds;
        existingHolding.shares -= shares;

        // If all shares are sold, remove the holding
        if (existingHolding.shares == 0) {
          _holdings.removeAt(existingHoldingIndex);
        }
        notifyListeners();
      } else {
        // Handle trying to sell more shares than owned
        print("Error: You cannot sell more shares than you own.");
      }
    } else {
       // Handle trying to sell a stock not in the portfolio
       print("Error: You do not own any shares of this stock.");
    }
  }
}
