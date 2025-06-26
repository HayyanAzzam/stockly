import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../providers/portfolio_provider.dart';

class PortfolioStorageService {
  // Finds the correct local path to store the file.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Gets a reference to the file itself.
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/portfolio.json');
  }

  // Reads the portfolio from the JSON file.
  Future<Map<String, dynamic>> loadPortfolio() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        // If the file doesn't exist, return a default portfolio structure.
        return {'cashBalance': 10000.0, 'holdings': []};
      }
      
      final contents = await file.readAsString();
      final data = json.decode(contents) as Map<String, dynamic>;
      return data;

    } catch (e) {
      print("Error loading portfolio: $e");
      // If there's an error, return a default portfolio.
      return {'cashBalance': 10000.0, 'holdings': []};
    }
  }

  // Saves the portfolio to the JSON file.
  Future<File> savePortfolio(PortfolioProvider portfolio) async {
    final file = await _localFile;
    final data = portfolio.toJson();
    // Convert the map to a pretty-printed JSON string and write it.
    final jsonString = JsonEncoder.withIndent('  ').convert(data);
    return file.writeAsString(jsonString);
  }
}
