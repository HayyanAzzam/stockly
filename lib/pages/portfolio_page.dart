import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Portfolio Value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('\$12,345.67', style: TextStyle(fontSize: 36, color: Colors.white)),
            Text('+ \$300.50 (2.5%) Today', style: TextStyle(color: const Color(0xFF22c55e), fontSize: 18)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _pieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Your Assets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAssetItem(context, 'AAPL', 'Apple Inc.', '10 Shares', '\$1,752.00', '+1.5%', const Color(0xFF22c55e)),
            _buildAssetItem(context, 'TSLA', 'Tesla, Inc.', '5 Shares', '\$1,254.00', '-2.1%', const Color(0xFFef4444)),
            _buildAssetItem(context, 'AMZN', 'Amazon.com, Inc.', '8 Shares', '\$1,084.00', '+0.8%', const Color(0xFF22c55e)),
          ],
        ),
      ),
    );
  }
  List<PieChartSectionData> _pieChartSections() {
    return [
      PieChartSectionData(
        color: Colors.blue,
        value: 40,
        title: 'AAPL',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: 30,
        title: 'TSLA',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: 30,
        title: 'AMZN',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  Widget _buildAssetItem(BuildContext context, String ticker, String name, String shares, String value, String change, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(child: Text(ticker[0])),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticker, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(shares, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(change, style: TextStyle(color: color)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
