class Formatters {
  static String formatCurrency(double value, {String symbol = '\$'}) {
    final format = NumberFormat.currency(locale: 'en_US', symbol: symbol, decimalDigits: 2);
    return format.format(value);
  }

  static String formatPercentage(double value) {
    final format = NumberFormat.decimalPercentPattern(locale: 'en_US', decimalDigits: 2);
    return format.format(value / 100);
  }
}
