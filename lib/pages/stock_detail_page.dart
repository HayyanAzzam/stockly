import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StockDetailPage extends StatefulWidget {
  final String stockId;
  const StockDetailPage({super.key, required this.stockId});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  String _selectedRange = '1Y';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockId),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.star_border))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apple Inc.', style: TextStyle(fontSize: 20, color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('\$175.20', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text('+2.50 (1.5%)', style: TextStyle(color: const Color(0xFF22c55e), fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                _mainChartData(),
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeRangeSelector(),
             const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Buy'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22c55e), padding: const EdgeInsets.symmetric(vertical: 16)))),
                const SizedBox(width: 16),
                 Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Sell'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444), padding: const EdgeInsets.symmetric(vertical: 16)))),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Key Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildKeyInfo(),
             const SizedBox(height: 32),
            const Text('Related News', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildRelatedNews(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['1D', '1W', '1M', '1Y', '5Y', 'ALL'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ranges.length,
        itemBuilder: (context, index) {
          final range = ranges[index];
          final isSelected = _selectedRange == range;
          return GestureDetector(
            onTap: () => setState(() => _selectedRange = range),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF22c55e) : Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  range,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
    Widget _buildKeyInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _infoRow('Market Cap', '2.7T'),
            _infoRow('P/E Ratio', '28.5'),
            _infoRow('Dividend Yield', '0.5%'),
             _infoRow('52 Week High', '\$198.23'),
              _infoRow('52 Week Low', '\$124.17'),
          ],
        ),
      ),
    );
  }
  
   Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
    Widget _buildRelatedNews() {
    return Column(
      children: [
        _newsCard('Apple Unveils New Product Lineup', 'TechCrunch'),
        _newsCard('Analysts Upgrade AAPL Stock', 'Reuters'),
      ],
    );
  }

  Widget _newsCard(String headline, String source) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(headline),
        subtitle: Text(source),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }


  LineChartData _mainChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
        getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3), FlSpot(2.6, 2), FlSpot(4.9, 5), FlSpot(6.8, 3.1), FlSpot(8, 4), FlSpot(9.5, 3), FlSpot(11, 4),
          ],
          isCurved: true,
          color: const Color(0xFF22c55e),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF22c55e).withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
