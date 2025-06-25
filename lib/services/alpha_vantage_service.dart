import 'dart:math';
import '../models/quote_model.dart';
import '../models/company_profile_model.dart';
import '../models/historical_data_model.dart';

/// A fake implementation of the AlphaVantageService that generates
/// seeded, believable random data for demonstration and development purposes.
class AlphaVantageService {

  static final Map<String, CompanyProfile> _mockProfiles = {
    'AAPL': CompanyProfile(symbol: 'AAPL', name: 'Apple Inc.', description: 'A technology company that designs, manufactures, and markets mobile communication and media devices, personal computers, and portable digital music players.', industry: 'Technology', marketCap: 3200.0, peRatio: 32.5, dividendYield: 0.5, high52: 220.50, low52: 165.21, beta: '1.29'),
    'SPY': CompanyProfile(symbol: 'SPY', name: 'SPDR S&P 500 ETF Trust', description: 'An exchange-traded fund that tracks the S&P 500 stock market index. It is one of the most popular ETFs in the world.', industry: 'ETF', marketCap: 535.0, peRatio: 25.1, dividendYield: 1.3, high52: 549.50, low52: 409.80, beta: '1.00'),
    'QQQ': CompanyProfile(symbol: 'QQQ', name: 'Invesco QQQ Trust', description: 'An ETF that tracks the Nasdaq-100 Index, which includes 100 of the largest non-financial companies listed on the Nasdaq Stock Market.', industry: 'ETF', marketCap: 280.0, peRatio: 35.2, dividendYield: 0.6, high52: 485.15, low52: 342.60, beta: '1.15'),
    'DIA': CompanyProfile(symbol: 'DIA', name: 'SPDR Dow Jones Industrial Average ETF', description: 'An ETF that tracks the Dow Jones Industrial Average, an index of 30 large, publicly-owned companies based in the United States.', industry: 'ETF', marketCap: 34.0, peRatio: 21.8, dividendYield: 1.8, high52: 401.30, low52: 323.70, beta: '0.95'),
    'IWM': CompanyProfile(symbol: 'IWM', name: 'iShares Russell 2000 ETF', description: 'An ETF that tracks the Russell 2000 Index, a small-cap stock market index of the smallest 2,000 stocks in the Russell 3000 Index.', industry: 'ETF', marketCap: 61.0, peRatio: 14.5, dividendYield: 1.1, high52: 212.40, low52: 162.10, beta: '1.21'),
    'GOOGL': CompanyProfile(symbol: 'GOOGL', name: 'Alphabet Inc. (Google)', description: 'A multinational technology company specializing in Internet-related services and products.', industry: 'Technology', marketCap: 2200.0, peRatio: 27.3, dividendYield: 0.1, high52: 185.50, low52: 120.10, beta: '1.05'),
    'AMZN': CompanyProfile(symbol: 'AMZN', name: 'Amazon.com, Inc.', description: 'A multinational technology company which focuses on e-commerce, cloud computing, digital streaming, and artificial intelligence.', industry: 'Retail', marketCap: 1950.0, peRatio: 52.1, dividendYield: 0.0, high52: 199.75, low52: 118.35, beta: '1.14'),
    'NVDA': CompanyProfile(symbol: 'NVDA', name: 'NVIDIA Corporation', description: 'A technology company known for its graphics processing units (GPUs) for the gaming and professional markets, as well as system on a chip units (SoCs) for the mobile computing and automotive market.', industry: 'Technology', marketCap: 3100.0, peRatio: 75.8, dividendYield: 0.03, high52: 140.76, low52: 39.23, beta: '1.68'),
    'MSFT': CompanyProfile(symbol: 'MSFT', name: 'Microsoft Corporation', description: 'A multinational technology corporation which produces computer software, consumer electronics, personal computers, and related services.', industry: 'Technology', marketCap: 3300.0, peRatio: 38.6, dividendYield: 0.7, high52: 452.75, low52: 309.49, beta: '0.87'),
    'BTC-USD': CompanyProfile(symbol: 'BTC-USD', name: 'Bitcoin', description: 'A decentralized digital currency that can be transferred on the peer-to-peer bitcoin network.', industry: 'Cryptocurrency', marketCap: 1200.0, peRatio: 0.0, dividendYield: 0.0, high52: 73750.07, low52: 24900.0, beta: 'N/A'),
  };

  /// Helper to round a double to a specific number of decimal places.
  static double _roundDouble(double val, int places) {
    double mod = pow(10.0, places).toDouble();
    return ((val * mod).round().toDouble() / mod);
  }

  static Future<Quote> getQuote(String symbol) async {
    final random = Random(symbol.hashCode);
    
    final basePrice = 50 + random.nextDouble() * 450;
    final prevClose = basePrice * (1 + (random.nextDouble() - 0.5) * 0.1);
    final change = basePrice - prevClose;
    final percentChange = (change / prevClose) * 100;

    await Future.delayed(Duration(milliseconds: 300 + random.nextInt(400)));

    return Quote(
      symbol: symbol,
      openPrice: _roundDouble(basePrice * (1 + (random.nextDouble() - 0.5) * 0.02), 2),
      highPrice: _roundDouble(basePrice * 1.02, 2),
      lowPrice: _roundDouble(basePrice * 0.98, 2),
      currentPrice: _roundDouble(basePrice, 2),
      previousClose: _roundDouble(prevClose, 2),
      change: _roundDouble(change, 2),
      percentChange: _roundDouble(percentChange, 2),
    );
  }

  static Future<CompanyProfile> getCompanyProfile(String symbol) async {
    final random = Random(symbol.hashCode);
    await Future.delayed(Duration(milliseconds: 200 + random.nextInt(300)));
    
    if (_mockProfiles.containsKey(symbol)) {
      return _mockProfiles[symbol]!;
    }
    return CompanyProfile(symbol: symbol, name: '$symbol Not Found', description: 'No data available for this mock symbol.', industry: 'N/A', marketCap: 0, peRatio: 0, dividendYield: 0, high52: 0, low52: 0, beta: '0.0');
  }

  static Future<List<HistoricalDataPoint>> getHistoricalData(String symbol, String period) async {
    final random = Random(symbol.hashCode);
    
    int numDataPoints;
    Duration timeStep;

    switch (period) {
      case '1D': numDataPoints = 78; timeStep = Duration(minutes: 5); break;
      case '1W': numDataPoints = 5; timeStep = Duration(days: 1); break;
      case '1M': numDataPoints = 22; timeStep = Duration(days: 1); break;
      case '3M': numDataPoints = 13; timeStep = Duration(days: 7); break;
      case '1Y': numDataPoints = 52; timeStep = Duration(days: 7); break;
      case '5Y': numDataPoints = 60; timeStep = Duration(days: 30); break;
      default: numDataPoints = 52; timeStep = Duration(days: 7); break;
    }

    List<HistoricalDataPoint> points = [];
    double lastClose = 50 + random.nextDouble() * 450;
    final now = DateTime.now();

    for (int i = 0; i < numDataPoints; i++) {
      double change = (random.nextDouble() - 0.48) * (lastClose * 0.05);
      double open = lastClose;
      double close = open + change;
      double high = max(open, close) * (1 + random.nextDouble() * 0.02);
      double low = min(open, close) * (1 - random.nextDouble() * 0.02);
      
      points.add(
        HistoricalDataPoint(
          date: now.subtract(timeStep * (numDataPoints - i)),
          open: _roundDouble(open, 2),
          high: _roundDouble(high, 2),
          low: _roundDouble(low, 2),
          close: _roundDouble(close, 2),
          volume: 100000 + random.nextDouble() * 5000000,
        )
      );
      lastClose = close;
    }
    
    await Future.delayed(Duration(milliseconds: 500 + random.nextInt(500)));
    
    return points;
  }
}

