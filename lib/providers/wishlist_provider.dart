import 'package:flutter/material.dart';
import '../screens/home_page.dart';

class WishlistProvider extends ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> _wishlists = {};
  String get _user => UserSession.email ?? 'guest';

  List<Map<String, dynamic>> get wishlist =>
      List.unmodifiable(_wishlists[_user] ?? []);

  void addToWishlist(Map<String, dynamic> stock) {
    _wishlists.putIfAbsent(_user, () => []);
    if (!_wishlists[_user]!.any((item) => item['symbol'] == stock['symbol'])) {
      _wishlists[_user]!.add(stock);
      notifyListeners();
    }
  }

  void removeFromWishlist(String symbol) {
    _wishlists[_user]?.removeWhere((item) => item['symbol'] == symbol);
    notifyListeners();
  }

  bool isInWishlist(String symbol) {
    return _wishlists[_user]?.any((item) => item['symbol'] == symbol) ?? false;
  }

  void clearWishlist() {
    _wishlists[_user]?.clear();
    notifyListeners();
  }
}
