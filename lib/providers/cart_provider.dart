import 'package:flutter/material.dart';
import '../screens/home_page.dart';

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
  final Map<String, List<CartItem>> _carts = {};
  String get _user => UserSession.email ?? 'guest';

  List<CartItem> get items => List.unmodifiable(_carts[_user] ?? []);

  void addItem(CartItem item) {
    _carts.putIfAbsent(_user, () => []);
    _carts[_user]!.add(item);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _carts[_user]?.remove(item);
    notifyListeners();
  }

  void clear() {
    _carts[_user]?.clear();
    notifyListeners();
  }

  double get total => (_carts[_user] != null)
      ? _carts[_user]!.fold(0.0, (sum, item) => sum + item.total)
      : 0.0;
}
