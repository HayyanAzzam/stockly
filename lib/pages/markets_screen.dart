import 'package:flutter/material.dart';
import 'package:stockly/pages/stock_detail_page.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Good morning', style: TextStyle(color: Colors.white70)),
          const Text('User', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          const Text('Market Indices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildMarketIndices(context),
          const SizedBox(height: 32),
          const Text('Stocks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStockLogos(context),
        ],
      ),
    );
  }

  Widget _buildStockLogos(BuildContext context) {
    final stocks = [
      {'name': 'Apple', 'ticker': 'AAPL', 'logo': 'assets/apple.png'},
      {'name': 'Google', 'ticker': 'GOOGL', 'logo': 'assets/google.png'},
      {'name': 'Microsoft', 'ticker': 'MSFT', 'logo': 'assets/microsoft.png'},
      {'name': 'Nvidia', 'ticker': 'NVDA', 'logo': 'assets/nvidia.png'},
      {'name': 'Amazon', 'ticker': 'AMZN', 'logo': 'assets/amazon.png'},
      {'name': 'Bitcoin', 'ticker': 'BTC-USD', 'logo': 'assets/bitcoin.png'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StockDetailPage(stockId: stocks[index]['ticker']!),
              ),
            );
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // child: Image.asset(stocks[index]['logo']!), // Use this when you have assets
              child: Center(child: Text(stocks[index]['ticker']!, style: const TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Portfolio Value', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('\$12,345.67', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Color(0xFF22c55e), size: 16),
                      const SizedBox(width: 4),
                      Text('+2.5% Today', style: TextStyle(color: Color(0xFF22c55e))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Cash', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('\$1,234.56', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketIndices(BuildContext context) {
    final indices = [
      {'name': 'S&P 500', 'value': '4,500.50', 'change': '+1.2%', 'color': const Color(0xFF22c55e)},
      {'name': 'NASDAQ', 'value': '14,000.80', 'change': '-0.5%', 'color': const Color(0xFFef4444)},
      {'name': 'DOW JONES', 'value': '35,000.10', 'change': '+0.8%', 'color': const Color(0xFF22c55e)},
    ];
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: indices.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(right: 16),
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(indices[index]['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(indices[index]['value'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    indices[index]['change'] as String,
                    style: TextStyle(color: indices[index]['color'] as Color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
