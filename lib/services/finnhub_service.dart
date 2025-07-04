import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class FinnhubService {
  static const String _apiKey = 'd1g7v8hr01qk4ao1mng0d1g7v8hr01qk4ao1mngg';
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  // Helper to get the current exchange rate from the provider
  double _getExchangeRate(BuildContext context) {
    final provider = Provider.of<CurrencyProvider>(context, listen: false);
    return provider.exchangeRate;
  }

  // Helper to get the current currency from the provider
  String _getCurrency(BuildContext context) {
    final provider = Provider.of<CurrencyProvider>(context, listen: false);
    return provider.currency;
  }

  Future<Map<String, dynamic>?> fetchQuote(
    String symbol,
    BuildContext context,
  ) async {
    print('Fetching quote for: $symbol');
    final url = Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Quote for $symbol: $data');
      final rate = _getExchangeRate(context);
      if (_getCurrency(context) != 'USD (\$)') {
        // Convert all price fields to selected currency
        for (var key in ['c', 'pc', 'h', 'l', 'o']) {
          if (data[key] != null) {
            data[key] = (data[key] as num) * rate;
          }
        }
      }
      return data;
    } else {
      print('Error fetching $symbol: ${response.statusCode} ${response.body}');
    }
    return null;
  }

  Future<Map<String, Map<String, dynamic>>> fetchQuotes(
    List<String> symbols,
    BuildContext context,
  ) async {
    print('Fetching quotes for symbols: $symbols');
    final Map<String, Map<String, dynamic>> results = {};
    for (final symbol in symbols) {
      final quote = await fetchQuote(symbol, context);
      if (quote != null) {
        results[symbol] = quote;
      } else {
        print('No quote returned for $symbol');
      }
    }
    print('All fetched quotes: $results');
    return results;
  }

  // Fetch historical candle data
  Future<Map<String, dynamic>?> fetchCandles({
    required String symbol,
    required String resolution,
    required int from,
    required int to,
    required BuildContext context,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/stock/candle?symbol=$symbol&resolution=$resolution&from=$from&to=$to&token=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rate = _getExchangeRate(context);
      if (_getCurrency(context) != 'USD (\$)') {
        // Convert all price arrays to selected currency
        for (var key in ['c', 'h', 'l', 'o']) {
          if (data[key] != null && data[key] is List) {
            data[key] = (data[key] as List)
                .map((v) => (v as num) * rate)
                .toList();
          }
        }
      }
      return data;
    }
    return null;
  }

  // Search for stocks by name or symbol
  Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    final url = Uri.parse('$_baseUrl/search?q=$query&token=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return List<Map<String, dynamic>>.from(data['result']);
      }
    }
    return [];
  }

  // Fetch general market news, filtered for stock/market relevance
  Future<List<Map<String, dynamic>>> fetchGeneralNews() async {
    final url = Uri.parse('$_baseUrl/news?category=general&token=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        final keywords = [
          'stock',
          'stocks',
          'market',
          'shares',
          'earnings',
          'company',
          'merger',
          'acquisition',
          'ipo',
          'etf',
          'dividend',
          'nasdaq',
          's&p',
          'dow',
          'nyse',
          'buy',
          'sell',
          'analyst',
          'forecast',
          'profit',
          'loss',
          'revenue',
          'financial',
          'investment',
          'portfolio',
          'quarter',
          'guidance',
          'outlook',
          'trading',
          'investor',
          'fund',
          'index',
          'indices',
          'bond',
          'split',
          'upgrade',
          'downgrade',
        ];
        return List<Map<String, dynamic>>.from(data).where((article) {
          final headline = (article['headline'] ?? '').toString().toLowerCase();
          final summary = (article['summary'] ?? '').toString().toLowerCase();
          return keywords.any(
            (kw) => headline.contains(kw) || summary.contains(kw),
          );
        }).toList();
      }
    }
    return [];
  }

  // Fetch currency exchange rate from USD to target currency
  Future<double> fetchExchangeRate(String targetCurrency) async {
    if (targetCurrency == 'USD (\$)') return 1.0;
    final code = targetCurrency.contains('EUR')
        ? 'EUR'
        : targetCurrency.contains('GBP')
        ? 'GBP'
        : 'USD';
    final url = Uri.parse(
      'https://api.exchangerate.host/latest?base=USD&symbols=$code',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['rates'] != null && data['rates'][code] != null) {
        return (data['rates'][code] as num).toDouble();
      }
    }
    return 1.0;
  }

  // Fetch company profile (name and logo)
  Future<Map<String, dynamic>?> fetchCompanyProfile(String symbol) async {
    final url = Uri.parse(
      '$_baseUrl/stock/profile2?symbol=$symbol&token=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    }
    return null;
  }

  // Fetch market indices (major North American indices)
  Future<List<Map<String, dynamic>>> fetchMarketIndices(
    BuildContext context,
  ) async {
    // Use ETF tickers for free quotes
    final List<Map<String, String>> indices = [
      {'symbol': 'SPY', 'name': 'S&P 500 ETF'},
      {'symbol': 'QQQ', 'name': 'NASDAQ 100 ETF'},
      {'symbol': 'DIA', 'name': 'Dow Jones ETF'},
      {'symbol': 'IWM', 'name': 'Russell 2000 ETF'},
      {'symbol': 'VIXY', 'name': 'VIX ETF'},
      {'symbol': 'TLT', 'name': '20Y Treasury ETF'},
    ];

    final List<Map<String, dynamic>> results = [];

    for (final index in indices) {
      final symbol = index['symbol']!;
      final name = index['name']!;
      final quote = await fetchQuote(symbol, context);
      if (quote != null) {
        final currentPrice = (quote['c'] as num?)?.toDouble() ?? 0.0;
        final prevClose = (quote['pc'] as num?)?.toDouble() ?? 0.0;
        final change = currentPrice - prevClose;
        results.add({
          'symbol': symbol,
          'name': name,
          'price': currentPrice,
          'change': change,
          'isUp': change >= 0,
        });
      }
    }

    return results;
  }

  // Fetch trending stocks (most active stocks)
  Future<List<Map<String, dynamic>>> fetchTrendingStocks(
    BuildContext context,
  ) async {
    final url = Uri.parse('$_baseUrl/stock/symbol?exchange=US&token=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        // Take a subset of popular stocks for trending
        final List<String> popularStocks = [
          'AAPL',
          'GOOGL',
          'MSFT',
          'AMZN',
          'NVDA',
          'TSLA',
          'META',
          'NFLX',
          'ADBE',
          'CRM',
          'PYPL',
          'INTC',
        ];

        final List<Map<String, dynamic>> results = [];

        for (final symbol in popularStocks) {
          final quote = await fetchQuote(symbol, context);
          final profile = await fetchCompanyProfile(symbol);

          if (quote != null && profile != null) {
            final currentPrice = (quote['c'] as num?)?.toDouble() ?? 0.0;
            final prevClose = (quote['pc'] as num?)?.toDouble() ?? 0.0;
            final change = currentPrice - prevClose;

            results.add({
              'symbol': symbol,
              'name': profile['name'] ?? symbol,
              'logo': profile['logo'],
              'price': currentPrice,
              'change': change,
              'isUp': change >= 0,
            });
          }
        }

        return results;
      }
    }

    return [];
  }

  // Fetch news for a specific stock symbol
  Future<List<Map<String, dynamic>>> fetchStockNews(String symbol) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 1, now.day); // last month
    final url = Uri.parse(
      '$_baseUrl/company-news?symbol=$symbol&from=${from.toIso8601String().substring(0, 10)}&to=${now.toIso8601String().substring(0, 10)}&token=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return [];
  }
}
