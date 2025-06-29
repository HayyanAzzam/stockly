import 'package:flutter/material.dart';
import 'package:stockly/pages/stock_detail_page.dart';

class NewsAndStockPage extends StatelessWidget {
  const NewsAndStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Top News', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildNewsItem(
            context,
            'Tech Stocks Rally on Positive Earnings Reports',
            'MarketWatch',
            '2 hours ago',
          ),
          _buildNewsItem(
            context,
            'Federal Reserve Signals Potential Rate Hikes',
            'Reuters',
            '5 hours ago',
          ),
          _buildNewsItem(
            context,
            'Oil Prices Surge Amidst Geopolitical Tensions',
            'Bloomberg',
            '8 hours ago',
          ),
          const SizedBox(height: 32),
          const Text('Trending Stocks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStockItem(context,'AAPL', 'Apple Inc.', '\$175.20', '+1.5%', const Color(0xFF22c55e)),
          _buildStockItem(context,'TSLA', 'Tesla, Inc.', '\$250.80', '-2.1%', const Color(0xFFef4444)),
          _buildStockItem(context,'AMZN', 'Amazon.com, Inc.', '\$135.50', '+0.8%', const Color(0xFF22c55e)),
        ],
      ),
    );
  }

  Widget _buildNewsItem(BuildContext context, String title, String source, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(source, style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Text(time, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(BuildContext context, String ticker, String name, String price, String change, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailPage(stockId: ticker),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticker, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(name, style: const TextStyle(color: Colors.white70)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(change, style: TextStyle(color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
