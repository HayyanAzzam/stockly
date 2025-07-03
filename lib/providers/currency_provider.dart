import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currency = 'USD (\$)';
  double _exchangeRate = 1.0;
  String get currency => _currency;
  double get exchangeRate => _exchangeRate;

  String get currencySymbol {
    if (_currency.contains('\$')) return '\$';
    if (_currency.contains('€')) return '€';
    if (_currency.contains('£')) return '£';
    return '';
  }

  // Hardcoded exchange rates
  double _getHardcodedRate(String currency) {
    if (currency.contains('EUR')) return 0.92;
    if (currency.contains('GBP')) return 0.79;
    return 1.0; // USD
  }

  void setCurrency(String newCurrency) {
    _currency = newCurrency;
    _exchangeRate = _getHardcodedRate(newCurrency);
    notifyListeners();
  }

  /// Formats a value with the current currency symbol. The value should already be converted if needed.
  static String formatCurrency(BuildContext context, double value) {
    final provider = Provider.of<CurrencyProvider>(context, listen: false);
    return '${provider.currencySymbol}${value.toStringAsFixed(2)}';
  }
}
