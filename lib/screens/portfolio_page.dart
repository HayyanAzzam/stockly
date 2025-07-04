import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_page.dart';
import '../providers/currency_provider.dart';
import 'stock_detail_page.dart';
import '../providers/market_provider.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({Key? key}) : super(key: key);

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  String selectedRange = 'Yearly';
  List<double> chartData = [
    100000.0,
    105000.0,
    95000.0,
    110000.0,
    90000.0,
    97000.0,
    96000.0,
    99000.0,
    98000.0,
    120000.0,
  ];

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    final assets = portfolioProvider.ownedStocks.entries.toList();
    final totalValue = portfolioProvider.portfolioValue;
    final availableCash = portfolioProvider.availableCash;
    // Calculate portfolio change as weighted sum of real change values
    double changeSum = 0.0;
    double valueSum = 0.0;
    for (final entry in assets) {
      final symbol = entry.key;
      final data = entry.value;
      final value = (data['value'] ?? 0.0) as double;
      // Find the real change value from marketStocks
      final marketStock = marketProvider.marketStocks.firstWhere(
        (s) => s['symbol'] == symbol,
        orElse: () => {},
      );
      final change = marketStock['change'] ?? 0.0;
      changeSum += change * (data['shares'] ?? 0.0);
      valueSum += value;
    }
    final percentChange = (valueSum > 0) ? (changeSum / valueSum) * 100 : 0.0;
    final isUp = changeSum >= 0;
    final chartColor = percentChange >= 0
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    // Ensure the last value in chartData always matches totalValue
    if (chartData.isNotEmpty && chartData.last != totalValue) {
      chartData[chartData.length - 1] = totalValue;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFB0B3B8),
                      child: Text(
                        (UserSession.username?.isNotEmpty == true)
                            ? UserSession.username![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning',
                          style: TextStyle(
                            color: Color(0xFFB0B3B8),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          (UserSession.username != null &&
                                  UserSession.username!.isNotEmpty)
                              ? UserSession.username![0].toUpperCase() +
                                    UserSession.username!.substring(1)
                              : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.search, color: Color(0xFFB0B3B8)),
                    const SizedBox(width: 16),
                    Icon(Icons.notifications_none, color: Color(0xFFB0B3B8)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Portfolio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF313338),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Assets Value',
                        style: TextStyle(
                          color: Color(0xFFB0B3B8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyProvider.formatCurrency(
                              context,
                              totalValue,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${isUp ? '+' : ''}${changeSum.abs().toStringAsFixed(2)} (${percentChange.abs().toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  color: isUp
                                      ? Color(0xFF22C55E)
                                      : Color(0xFFEF4444),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Icon(
                                Icons.show_chart,
                                color: Color(0xFFB0B3B8),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Available Cash',
                        style: TextStyle(
                          color: Color(0xFFB0B3B8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyProvider.formatCurrency(context, availableCash),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeFilterButton(
                      label: 'Daily',
                      selected: selectedRange == 'Daily',
                      onTap: () => setState(() {
                        selectedRange = 'Daily';
                        chartData = [
                          100000.0,
                          100050.0,
                          100020.0,
                          100080.0,
                          100030.0,
                          100100.0,
                          totalValue,
                        ];
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TimeFilterButton(
                      label: 'Weekly',
                      selected: selectedRange == 'Weekly',
                      onTap: () => setState(() {
                        selectedRange = 'Weekly';
                        chartData = [
                          100000.0,
                          100200.0,
                          100150.0,
                          100300.0,
                          100250.0,
                          100400.0,
                          totalValue,
                        ];
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TimeFilterButton(
                      label: 'Monthly',
                      selected: selectedRange == 'Monthly',
                      onTap: () => setState(() {
                        selectedRange = 'Monthly';
                        chartData = [
                          100000.0,
                          101500.0,
                          99500.0,
                          102500.0,
                          98500.0,
                          97500.0,
                          96500.0,
                          98000.0,
                          99000.0,
                          totalValue,
                        ];
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TimeFilterButton(
                      label: 'Yearly',
                      selected: selectedRange == 'Yearly',
                      onTap: () => setState(() {
                        selectedRange = 'Yearly';
                        chartData = [
                          100000.0,
                          105000.0,
                          95000.0,
                          110000.0,
                          90000.0,
                          97000.0,
                          96000.0,
                          99000.0,
                          98000.0,
                          totalValue,
                        ];
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF23272A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) => FlSpot(i.toDouble(), chartData[i]),
                          ),
                          isCurved: true,
                          color: chartColor,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: chartColor.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Assets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (assets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'You have no assets as of yet.',
                      style: TextStyle(
                        color: Color(0xFFB0B3B8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ...assets.map((entry) {
                    final symbol = entry.key;
                    final data = entry.value;
                    final shares = data['shares'] ?? 0.0;
                    final value = data['value'] ?? 0.0;
                    final marketProvider = Provider.of<MarketProvider>(
                      context,
                      listen: false,
                    );
                    // Use real change value for each asset
                    final marketStock = marketProvider.marketStocks.firstWhere(
                      (s) => s['symbol'] == symbol,
                      orElse: () => {},
                    );
                    final change = marketStock['change'] ?? 0.0;
                    final isUp = change >= 0;
                    final name = data['name'] ?? symbol;
                    final logo = data['logo'];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockDetailPage(symbol: symbol, name: name),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF313338),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: logo != null && logo != ''
                                  ? NetworkImage(logo)
                                  : null,
                              child: (logo == null || logo == '')
                                  ? Text(
                                      symbol.isNotEmpty ? symbol[0] : '?',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    '$shares shares',
                                    style: const TextStyle(
                                      color: Color(0xFFB0B3B8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyProvider.formatCurrency(
                                    context,
                                    value,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${isUp ? '+' : ''}${change.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isUp
                                        ? Color(0xFF22C55E)
                                        : Color(0xFFEF4444),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeFilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF313338) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6B7280)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB0B3B8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
