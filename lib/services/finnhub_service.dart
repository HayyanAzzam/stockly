import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote_model.dart';

class FinnhubService {
  // --- IMPORTANT ---
  // Double-check you have replaced 'YOUR_API_KEY' with your actual key.
  static const String _apiKey = 'd186hq1r01ql1b4m49e0d186hq1r01ql1b4m49eg'; 
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  static Future<Quote> getQuote(String symbol) async {
    final url = Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        
        // --- DEBUGGING LINE ---
        // This will print the raw JSON data to your debug console.
        print('Response for $symbol: ${response.body}');
        
        final jsonResponse = json.decode(response.body);
        return Quote.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load quote for $symbol. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}

