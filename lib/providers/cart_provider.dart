import 'package:flutter/material.dart';

class CartItem {
  final String symbol;
  final String name;
  final double price;
  final double shares;
  final String type; // 'buy' or 'sell'

  CartItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.shares,
    required this.type,
  });

  double get total => price * shares;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  double get total => _items.fold(0.0, (sum, item) => sum + item.total);
}
