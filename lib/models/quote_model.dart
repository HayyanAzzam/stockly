class Quote {
  final String symbol;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double currentPrice;
  final double previousClose;
  final double change;
  final double percentChange;
  final String? error; // For API notes or errors

  Quote({
    required this.symbol,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.currentPrice,
    required this.previousClose,
    required this.change,
    required this.percentChange,
    this.error,
  });

  // Factory constructor for creating a new Quote instance from Alpha Vantage JSON.
  factory Quote.fromJson(Map<String, dynamic> json) {
    // Alpha Vantage returns a "Note" for high usage on the free tier, which we treat as an error.
    if (json.containsKey('Note')) {
      return Quote(
        error: json['Note'],
        symbol: '', openPrice: 0, highPrice: 0, lowPrice: 0,
        currentPrice: 0, previousClose: 0, change: 0, percentChange: 0,
      );
    }
    
    // Check if the main "Global Quote" key exists and is not empty.
    if (!json.containsKey('Global Quote') || (json['Global Quote'] as Map).isEmpty) {
        return Quote(
        error: 'Invalid data format from API.',
        symbol: '', openPrice: 0, highPrice: 0, lowPrice: 0,
        currentPrice: 0, previousClose: 0, change: 0, percentChange: 0,
      );
    }

    final globalQuote = json['Global Quote'] as Map<String, dynamic>;

    // Helper to parse string values to double safely
    double parseDouble(String key) {
      return double.tryParse(globalQuote[key] ?? '0.0') ?? 0.0;
    }
    
    // Helper to parse the percentage string (e.g., "0.4405%")
    double parsePercent(String key) {
        final value = globalQuote[key] as String? ?? '0.0%';
        return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }

    return Quote(
      symbol: globalQuote['01. symbol'] ?? '',
      openPrice: parseDouble('02. open'),
      highPrice: parseDouble('03. high'),
      lowPrice: parseDouble('04. low'),
      currentPrice: parseDouble('05. price'),
      previousClose: parseDouble('08. previous close'),
      change: parseDouble('09. change'),
      percentChange: parsePercent('10. change percent'),
    );
  }

  // A simple helper to determine if the stock is up or down
  bool get isUp => change >= 0;
}

