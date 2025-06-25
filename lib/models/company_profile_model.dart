class CompanyProfile {
  final String symbol;
  final String name;
  final String description;
  final String industry;
  final double marketCap;
  final double peRatio;
  final double dividendYield;
  final double high52;
  final double low52;
  final String beta; // Using beta as a string for simplicity

  CompanyProfile({
    required this.symbol,
    required this.name,
    required this.description,
    required this.industry,
    required this.marketCap,
    required this.peRatio,
    required this.dividendYield,
    required this.high52,
    required this.low52,
    required this.beta,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    double parseDouble(String key) => double.tryParse(json[key] ?? '0.0') ?? 0.0;
    
    return CompanyProfile(
      symbol: json['Symbol'] ?? '',
      name: json['Name'] ?? 'N/A',
      description: json['Description'] ?? 'No description available.',
      industry: json['Industry'] ?? 'N/A',
      marketCap: parseDouble('MarketCapitalization') / 1000000000, // Convert to billions
      peRatio: parseDouble('PERatio'),
      dividendYield: parseDouble('DividendYield') * 100, // Convert to percentage
      high52: parseDouble('52WeekHigh'),
      low52: parseDouble('52WeekLow'),
      beta: json['Beta'] ?? 'N/A',
    );
  }
}
