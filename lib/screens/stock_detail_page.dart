import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../services/finnhub_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'home_page.dart';
import '../providers/currency_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class StockDetailPage extends StatefulWidget {
  final String symbol;
  final String name;
  const StockDetailPage({Key? key, required this.symbol, required this.name})
    : super(key: key);

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  String selectedRange = '1Y';
  List<FlSpot> chartData = [];
  bool isLoading = true;
  String? error;

  final FinnhubService _finnhubService = FinnhubService();

  double? currentPrice;
  double? prevClose;
  double? change;
  double? percent;
  bool priceLoading = true;

  String? companyName;
  String? companyLogo;
  bool profileLoading = true;

  late Future<List<Map<String, dynamic>>> _newsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchProfile();
      fetchPrice();
      fetchChartData();
    });
    _newsFuture = _finnhubService.fetchStockNews(widget.symbol);
  }

  Future<void> fetchProfile() async {
    setState(() {
      profileLoading = true;
    });
    final profile = await _finnhubService.fetchCompanyProfile(widget.symbol);
    if (mounted) {
      setState(() {
        companyName = profile?['name'] ?? widget.name;
        companyLogo = profile?['logo'];
        profileLoading = false;
      });
    }
  }

  Future<void> fetchPrice() async {
    setState(() {
      priceLoading = true;
    });
    final quote = await _finnhubService.fetchQuote(widget.symbol, context);
    if (quote != null && mounted) {
      setState(() {
        currentPrice = (quote['c'] as num?)?.toDouble();
        prevClose = (quote['pc'] as num?)?.toDouble();
        if (currentPrice != null && prevClose != null) {
          change = currentPrice! - prevClose!;
          percent = prevClose! != 0 ? (change! / prevClose!) * 100 : 0;
        }
        priceLoading = false;
      });
    } else {
      setState(() {
        priceLoading = false;
      });
    }
  }

  Future<void> fetchChartData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    try {
      int points;
      double base;
      double volatility;
      final price = (currentPrice ?? 0.0);
      if (selectedRange == '1D') {
        points = 12;
        base = price - 2;
        volatility = 1.5;
      } else if (selectedRange == '1W') {
        points = 7;
        base = price - 8;
        volatility = 4;
      } else if (selectedRange == '1M') {
        points = 30;
        base = price - 15;
        volatility = 8;
      } else {
        points = 12;
        base = price - 40;
        volatility = 20;
      }
      final rand = Random();
      List<double> values = [];
      double last = base;
      for (int i = 0; i < points - 1; i++) {
        double change = (rand.nextDouble() - 0.5) * volatility;
        last = (last + change).clamp(base, price + volatility);
        values.add(double.parse(last.toStringAsFixed(2)));
      }
      values.add(price); // Always end at current price
      List<FlSpot> spots = [
        for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ];
      setState(() {
        chartData = spots;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error generating chart data.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = currentPrice;
    final isUp = (change ?? 0) >= 0;
    final color = isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final sharesOwned =
        portfolioProvider.ownedStocks[widget.symbol]?['shares'] ?? 0.0;
    final availableCash = portfolioProvider.availableCash;

    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (companyLogo != null && companyLogo != '')
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(companyLogo!),
                  radius: 14,
                ),
              ),
            Text(
              widget.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              final wishlistProvider = Provider.of<WishlistProvider>(context);
              final inWishlist = wishlistProvider.isInWishlist(widget.symbol);
              return IconButton(
                icon: Icon(
                  inWishlist ? Icons.star : Icons.star_border,
                  color: inWishlist ? Colors.amber : Colors.white,
                ),
                onPressed: () {
                  if (!inWishlist) {
                    wishlistProvider.addToWishlist({
                      'symbol': widget.symbol,
                      'description': widget.name,
                    });
                  } else {
                    wishlistProvider.removeFromWishlist(widget.symbol);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            profileLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    companyName ?? widget.name,
                    style: const TextStyle(
                      color: Color(0xFFB0B3B8),
                      fontSize: 16,
                    ),
                  ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                priceLoading
                    ? const SizedBox(
                        width: 60,
                        height: 36,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        CurrencyProvider.formatCurrency(context, price ?? 0.0),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                const SizedBox(width: 12),
                priceLoading
                    ? const SizedBox(width: 40, height: 18)
                    : Text(
                        (change != null && percent != null)
                            ? '${isUp ? '+' : ''}${change!.toStringAsFixed(2)} (${percent!.toStringAsFixed(2)}%)'
                            : '--',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (error != null
                        ? Center(
                            child: Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : (chartData.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No data available',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: chartData,
                                        isCurved: true,
                                        color: color,
                                        barWidth: 3,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: color.withOpacity(0.15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeFrameButton(
                  label: '1D',
                  selected: selectedRange == '1D',
                  onTap: () {
                    setState(() => selectedRange = '1D');
                    fetchChartData();
                  },
                ),
                _TimeFrameButton(
                  label: '1W',
                  selected: selectedRange == '1W',
                  onTap: () {
                    setState(() => selectedRange = '1W');
                    fetchChartData();
                  },
                ),
                _TimeFrameButton(
                  label: '1M',
                  selected: selectedRange == '1M',
                  onTap: () {
                    setState(() => selectedRange = '1M');
                    fetchChartData();
                  },
                ),
                _TimeFrameButton(
                  label: '1Y',
                  selected: selectedRange == '1Y',
                  onTap: () {
                    setState(() => selectedRange = '1Y');
                    fetchChartData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BuySellDialog(
                            symbol: widget.symbol,
                            name: widget.name,
                            price: price ?? 0.0,
                            sharesOwned: sharesOwned,
                            availableCash: availableCash,
                            isBuy: true,
                          ),
                        );
                      },
                      child: const Text(
                        'Buy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: sharesOwned > 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6B7280),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: sharesOwned > 0
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => BuySellDialog(
                                  symbol: widget.symbol,
                                  name: widget.name,
                                  price: price ?? 0.0,
                                  sharesOwned: sharesOwned,
                                  availableCash: availableCash,
                                  isBuy: false,
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        'Sell',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: sharesOwned > 0
                              ? const Color(0xFFEF4444)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Relevant News',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load news',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No news available',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  final newsList = snapshot.data!;
                  return ListView.builder(
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final news = newsList[index];
                      final headline = news['headline'] ?? '';
                      final url = news['url'] ?? '';
                      final datetime = news['datetime'] != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                              news['datetime'] * 1000,
                            )
                          : null;
                      final dateStr = datetime != null
                          ? '${datetime.month}/${datetime.day}/${datetime.year}'
                          : '';
                      return _NewsTile(
                        title: headline,
                        date: dateStr,
                        onTap: () async {
                          if (url.isEmpty) return;
                          final uri = Uri.parse(url);
                          try {
                            final launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!launched && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open the article.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open the article.'),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeFrameButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeFrameButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF6B7280) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6B7280)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final String title;
  final String date;
  final VoidCallback? onTap;
  const _NewsTile({required this.title, required this.date, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF23272A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6B7280), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(color: Color(0xFFB0B3B8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class BuySellDialog extends StatefulWidget {
  final String symbol;
  final String name;
  final double price;
  final double sharesOwned;
  final double availableCash;
  final bool isBuy;
  const BuySellDialog({
    Key? key,
    required this.symbol,
    required this.name,
    required this.price,
    required this.sharesOwned,
    required this.availableCash,
    required this.isBuy,
  }) : super(key: key);

  @override
  State<BuySellDialog> createState() => _BuySellDialogState();
}

class _BuySellDialogState extends State<BuySellDialog> {
  final TextEditingController _sharesController = TextEditingController();
  String? error;

  double get shares => double.tryParse(_sharesController.text) ?? 0.0;
  double get estimatedTotal => (shares * widget.price);

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = Provider.of<PortfolioProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final canBuy =
        widget.isBuy && shares > 0 && estimatedTotal <= widget.availableCash;
    final canSell = !widget.isBuy && shares > 0 && shares <= widget.sharesOwned;
    return Dialog(
      backgroundColor: const Color(0xFF23272A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isBuy
                      ? 'Buy ${widget.symbol}'
                      : 'Sell ${widget.symbol}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Number of Shares',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sharesController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF23272A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.isBuy
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF22C55E),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.isBuy
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                ),
                hintText: '0',
                hintStyle: const TextStyle(color: Color(0xFFB0B3B8)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF23272A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6B7280)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Price:',
                        style: TextStyle(color: Color(0xFFB0B3B8)),
                      ),
                      Text(
                        CurrencyProvider.formatCurrency(context, widget.price),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shares Owned:',
                        style: TextStyle(color: Color(0xFFB0B3B8)),
                      ),
                      Text(
                        '${widget.sharesOwned.toStringAsFixed(2)} shares',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Cash:',
                        style: TextStyle(color: Color(0xFFB0B3B8)),
                      ),
                      Text(
                        CurrencyProvider.formatCurrency(
                          context,
                          widget.availableCash,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFF6B7280)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Total:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyProvider.formatCurrency(
                          context,
                          estimatedTotal,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            if (widget.isBuy)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canBuy
                          ? () {
                              cartProvider.addItem(
                                CartItem(
                                  symbol: widget.symbol,
                                  name: widget.name,
                                  price: widget.price,
                                  shares: shares,
                                  type: 'buy',
                                ),
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to cart')),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (!widget.isBuy)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _sharesController.text = widget.sharesOwned
                              .toStringAsFixed(2);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Sell All',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF313338),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (widget.isBuy ? canBuy : canSell)
                        ? () {
                            if (widget.isBuy) {
                              portfolioProvider.buyStock(
                                widget.symbol,
                                widget.price,
                                shares,
                              );
                            } else {
                              portfolioProvider.sellStock(
                                widget.symbol,
                                widget.price,
                                shares,
                              );
                            }
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isBuy
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
