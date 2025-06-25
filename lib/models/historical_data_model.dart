class HistoricalDataPoint {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  HistoricalDataPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory HistoricalDataPoint.fromDailyJson(String dateString, Map<String, dynamic> json) {
    return HistoricalDataPoint(
      date: DateTime.parse(dateString),
      open: double.parse(json['1. open']),
      high: double.parse(json['2. high']),
      low: double.parse(json['3. low']),
      close: double.parse(json['4. close']),
      volume: double.parse(json['5. volume']),
    );
  }

   factory HistoricalDataPoint.fromIntradayJson(String dateString, Map<String, dynamic> json) {
    return HistoricalDataPoint(
      date: DateTime.parse(dateString),
      open: double.parse(json['1. open']),
      high: double.parse(json['2. high']),
      low: double.parse(json['3. low']),
      close: double.parse(json['4. close']),
      volume: double.parse(json['5. volume']),
    );
  }
}
