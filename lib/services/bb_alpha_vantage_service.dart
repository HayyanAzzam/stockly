import 'dart:convert';
import 'dart:math'; // Import the dart:math library to use the min() function
import 'package:http/http.dart' as http;
import '../models/quote_model.dart';
import '../models/company_profile_model.dart';
import '../models/historical_data_model.dart';

class AlphaVantageService {
  // --- IMPORTANT ---
  // Remember to paste your free API key from Alpha Vantage here.
  static const String _apiKey = 'H3HXK3SAJHT3DTKA'; 
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  /// Fetches the latest quote data for a given symbol.
  static Future<Quote> getQuote(String symbol) async {
     final url = Uri.parse('$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Print the raw JSON response to the debug console for inspection.
        print('Quote for $symbol: ${response.body}');
        return Quote.fromJson(json.decode(response.body));
      } else {
        // Handle server errors (e.g., 500 Internal Server Error).
        throw Exception('Failed to load quote');
      }
    } catch (e) {
      // Handle network or other exceptions.
      throw Exception('Failed to connect: $e');
    }
  }

  /// Fetches the company overview and key metrics.
  static Future<CompanyProfile> getCompanyProfile(String symbol) async {
    final url = Uri.parse('$_baseUrl?function=OVERVIEW&symbol=$symbol&apikey=$_apiKey');
     try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Profile for $symbol: ${response.body}');
        return CompanyProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load company profile');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  /// Fetches historical price data for building the chart.
  static Future<List<HistoricalDataPoint>> getHistoricalData(String symbol, String period) async {
    String function;
    String timeSeriesKey;
    bool isIntraday = false;

    // Determine the correct API function and response key based on the selected time period.
    switch (period) {
      case '1D':
        function = 'TIME_SERIES_INTRADAY';
        timeSeriesKey = 'Time Series (5min)';
        isIntraday = true;
        break;
      case '1W':
      case '1M':
        function = 'TIME_SERIES_DAILY_ADJUSTED';
        timeSeriesKey = 'Time Series (Daily)';
        break;
      case '3M':
      case '1Y':
      case '5Y':
      default:
        function = 'TIME_SERIES_WEEKLY_ADJUSTED';
        timeSeriesKey = 'Weekly Adjusted Time Series';
        break;
    }

    String urlString = '$_baseUrl?function=$function&symbol=$symbol&apikey=$_apiKey';
    // Add the interval parameter only if it's an intraday request.
    if(isIntraday) {
      urlString += '&interval=5min';
    }

    final url = Uri.parse(urlString);
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Print the beginning of the response to avoid flooding the console.
        print('Historical for $symbol ($period): ${response.body.substring(0, min(200, response.body.length))}...');
        
        final data = json.decode(response.body);
        
        // Check if the expected data key exists in the response.
        if (data[timeSeriesKey] == null) {
          print('Error: Could not find key "$timeSeriesKey" in historical data response.');
          // Check for a "Note" which indicates an API limit was reached.
          if (data['Note'] != null) {
              throw Exception('API call limit reached: ${data['Note']}');
          }
          return []; // Return an empty list if data is not available.
        }

        final Map<String, dynamic> timeSeries = data[timeSeriesKey];
        List<HistoricalDataPoint> points = [];
        
        // Iterate over the map of dates and price points.
        timeSeries.forEach((date, pointData) {
           points.add(isIntraday 
             ? HistoricalDataPoint.fromIntradayJson(date, pointData) 
             : HistoricalDataPoint.fromDailyJson(date, pointData));
        });

        // The API returns data in reverse chronological order, so we reverse the list
        // to have the oldest data point first for charting.
        return points.reversed.toList();
      } else {
        throw Exception('Failed to load historical data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect or parse historical data: $e');
    }
  }
}

