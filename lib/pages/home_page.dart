import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';

import '../services/alpha_vantage_service.dart';
import '../providers/portfolio_provider.dart';
import '../models/quote_model.dart';
import '../models/company_profile_model.dart';
import '../models/historical_data_model.dart';

class StockDetailPage extends StatefulWidget {
  final String stockSymbol;
  const StockDetailPage({Key? key, required this.stockSymbol}) : super(key: key);

  @override
  _StockDetailPageState createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> with SingleTickerProviderStateMixin {
  Quote? _quote;
  CompanyProfile? _profile;
  List<HistoricalDataPoint>? _historicalData;

  Timer? _timer;
  late TabController _tabController;
  String _selectedPeriod = '1Y';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData(); 
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) => _updateQuote());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    final results = await Future.wait([
      AlphaVantageService.getQuote(widget.stockSymbol),
      AlphaVantageService.getCompanyProfile(widget.stockSymbol),
      AlphaVantageService.getHistoricalData(widget.stockSymbol, _selectedPeriod),
    ]);
    if (mounted) {
      final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
      setState(() {
        _quote = results[0] as Quote;
        _profile = results[1] as CompanyProfile;
        _historicalData = results[2] as List<HistoricalDataPoint>;
      });
       portfolio.updateLivePrice(widget.stockSymbol, _quote!.currentPrice);
    }
  }

  Future<void> _updateQuote() async {
    final newQuote = await AlphaVantageService.getQuote(widget.stockSymbol);
     if (mounted) {
       Provider.of<PortfolioProvider>(context, listen: false)
          .updateLivePrice(widget.stockSymbol, newQuote.currentPrice);
       setState(() {
         _quote = newQuote;
         // Make the graph update live by appending the new price
         if (_historicalData != null && _historicalData!.isNotEmpty) {
           _historicalData!.add(HistoricalDataPoint(
             date: DateTime.now(),
             close: newQuote.currentPrice,
             open: newQuote.openPrice,
             high: newQuote.highPrice,
             low: newQuote.lowPrice,
             volume: 0,
           ));
           // To avoid the list growing indefinitely, remove the oldest point
           if (_historicalData!.length > 100) { // Keep a fixed window of points
             _historicalData!.removeAt(0);
           }
         }
       });
     }
  }
  
  void _updatePeriod(String period) async {
    setState(() {
      _selectedPeriod = period;
      _historicalData = null; 
    });
    final newHistoricalData = await AlphaVantageService.getHistoricalData(widget.stockSymbol, _selectedPeriod);
    if(mounted) {
      setState(() {
        _historicalData = newHistoricalData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        actions: [
            IconButton(icon: const Icon(Icons.add_chart_sharp, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: (_quote == null || _profile == null)
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : _buildPageContent(_quote!, _profile!),
    );
  }

  Widget _buildPageContent(Quote quote, CompanyProfile profile) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(quote, profile),
                  const SizedBox(height: 24),
                  _buildChart(),
                  const SizedBox(height: 16),
                  _buildTimePeriodSelector(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ];
      },
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabView(quote, profile)),
        ],
      ),
    );
  }

  Widget _buildHeader(Quote quote, CompanyProfile profile) {
    final portfolio = context.watch<PortfolioProvider>();
    final initialPrice = portfolio.initialSessionPrices[quote.symbol] ?? quote.currentPrice;
    final dailyChange = quote.currentPrice - initialPrice;
    final dailyPercent = initialPrice > 0 ? (dailyChange / initialPrice) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(profile.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(profile.symbol, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        const SizedBox(height: 16),
        Text('\$${quote.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text(
              '${dailyChange >= 0 ? '+' : ''}\$${dailyChange.toStringAsFixed(2)} (${dailyPercent.toStringAsFixed(2)}%)',
              style: TextStyle(color: dailyChange >= 0 ? Colors.green : Colors.red, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text('Today', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildChart() {
     if (_historicalData == null) {
        return Container(height: 200, child: const Center(child: CircularProgressIndicator(color: Colors.white)));
      }
      if (_historicalData!.isEmpty) {
        return Container(height: 200, child: Center(child: Text("Chart data unavailable.", style: TextStyle(color: Colors.grey))));
      }
      
      final dataPoints = _historicalData!;
      final minVal = dataPoints.map((p) => p.close).reduce(min);
      final maxVal = dataPoints.map((p) => p.close).reduce(max);
      List<Color> gradientColors = [];
      List<double> stops = [];
      for (int i = 0; i < dataPoints.length; i++) {
        final isUp = i > 0 ? dataPoints[i].close >= dataPoints[i-1].close : true;
        gradientColors.add(isUp ? Colors.green : Colors.red);
        stops.add(i / (dataPoints.length - 1));
      }
      return Container(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (dataPoints.length - 1).toDouble(),
              minY: minVal * 0.98,
              maxY: maxVal * 1.02,
              lineBarsData: [
                LineChartBarData(
                  spots: dataPoints.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.close);
                  }).toList(),
                  isCurved: true,
                  gradient: LinearGradient(colors: gradientColors, stops: stops),
                  barWidth: 2.5,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
                      stops: stops,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((barSpot) {
                      return LineTooltipItem(
                        '\$${barSpot.y.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      FlLine(color: Colors.grey[600], strokeWidth: 1, dashArray: [3, 3]),
                      FlDotData(
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: barData.gradient?.colors[index] ?? barData.color ?? Colors.green,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
  }

  Widget _buildTimePeriodSelector() {
    final periods = ['1D', '1W', '1M', '3M', '1Y', '5Y'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return GestureDetector(
          onTap: () => _updatePeriod(period),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.withOpacity(0.8) : Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              period,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.green,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey[400],
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Your Holdings'),
        Tab(text: 'Performance'),
      ],
    );
  }

  Widget _buildTabView(Quote quote, CompanyProfile profile) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(profile, quote),
        _buildHoldingsTab(quote),
        _buildPerformanceTab(profile),
      ],
    );
  }

  Widget _buildOverviewTab(CompanyProfile profile, Quote quote) {
     return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard("About ${profile.symbol}", profile.description),
          const SizedBox(height: 16),
          _buildInfoCard("Risk Level", "Carries moderate risk, subject to market volatility and economic downturns.", titleColor: Colors.amber),
          const SizedBox(height: 24),
          _buildActionButtons(quote),
        ],
      ),
    );
  }

  Widget _buildHoldingsTab(Quote quote) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text('Your detailed holdings will be displayed here.', style: TextStyle(color: Colors.grey)),
            ),
          ),
          _buildActionButtons(quote),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(CompanyProfile profile) {
    return const Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text('Detailed performance metrics will be displayed here.', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String content, {Color titleColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: Colors.grey[300], height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Quote quote) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _showTradeDialog(context, isBuy: true, quote: quote),
          child: Text('Buy ${widget.stockSymbol}', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
             side: BorderSide(color: Colors.red),
             minimumSize: const Size(double.infinity, 50),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _showTradeDialog(context, isBuy: false, quote: quote),
          child: Text('Sell ${widget.stockSymbol}', style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      ],
    );
  }

  void _showTradeDialog(BuildContext context, {required bool isBuy, required Quote quote}) {
    final TextEditingController controller = TextEditingController();
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('${isBuy ? 'Buy' : 'Sell'} ${widget.stockSymbol}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Cash: \$${portfolio.cashBalance.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('Current Price: \$${quote.currentPrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Number of Shares',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                ),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}'))],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isBuy ? Colors.green : Colors.red),
              onPressed: () {
                final double? shares = double.tryParse(controller.text);
                if (shares != null && shares > 0) {
                  if (isBuy) {
                    portfolio.buyStock(widget.stockSymbol, shares, quote.currentPrice);
                  } else {
                    portfolio.sellStock(widget.stockSymbol, shares, quote.currentPrice);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

