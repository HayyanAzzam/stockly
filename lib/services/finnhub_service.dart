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

  // Fetch general market news
  Future<List<Map<String, dynamic>>> fetchGeneralNews() async {
    final url = Uri.parse('$_baseUrl/news?category=general&token=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
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
}
