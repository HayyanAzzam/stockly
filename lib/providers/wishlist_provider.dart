import 'package:flutter/material.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _wishlist = [];

  List<Map<String, dynamic>> get wishlist => List.unmodifiable(_wishlist);

  void addToWishlist(Map<String, dynamic> stock) {
    if (!_wishlist.any((item) => item['symbol'] == stock['symbol'])) {
      _wishlist.add(stock);
      notifyListeners();
    }
  }

  void removeFromWishlist(String symbol) {
    _wishlist.removeWhere((item) => item['symbol'] == symbol);
    notifyListeners();
  }

  bool isInWishlist(String symbol) {
    return _wishlist.any((item) => item['symbol'] == symbol);
  }
}
