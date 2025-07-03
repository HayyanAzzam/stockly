import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/finnhub_service.dart';
import 'stock_detail_page.dart';
import 'home_page.dart';
import '../providers/currency_provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final FinnhubService _service = FinnhubService();
  Map<String, Map<String, dynamic>> _quotes = {};
  Map<String, Map<String, dynamic>> _profiles = {};
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchQuotesAndProfiles();
  }

  Future<void> _fetchQuotesAndProfiles() async {
    final wishlist = Provider.of<WishlistProvider>(
      context,
      listen: false,
    ).wishlist;
    if (wishlist.isEmpty) return;
    setState(() => _loading = true);
    final symbols = wishlist.map((e) => e['symbol'] as String).toList();
    final quotes = await _service.fetchQuotes(symbols, context);
    final Map<String, Map<String, dynamic>> profiles = {};
    for (final symbol in symbols) {
      profiles[symbol] = await _service.fetchCompanyProfile(symbol) ?? {};
    }
    setState(() {
      _quotes = quotes;
      _profiles = profiles;
      _loading = false;
    });
  }

  // Public method to refresh quotes externally
  Future<void> refreshQuotes() async {
    await _fetchQuotesAndProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlist = wishlistProvider.wishlist;
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        title: const Text(
          'My Wishlist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && wishlist.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Your wishlist is empty',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_loading && wishlist.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: wishlist.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final stock = wishlist[index];
                    final quote = _quotes[stock['symbol']];
                    final price = quote != null ? quote['c'] : null;
                    final prevClose = quote != null ? quote['pc'] : null;
                    final change = (price != null && prevClose != null)
                        ? ((price - prevClose) / prevClose * 100)
                        : null;
                    final isUp = (change ?? 0) >= 0;
                    final profile = _profiles[stock['symbol']] ?? {};
                    final logo = profile['logo'];
                    final name = profile['name'] ?? stock['symbol'];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockDetailPage(
                              symbol: stock['symbol'],
                              name: name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF23272A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF313338)),
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
                                      stock['symbol'].isNotEmpty
                                          ? stock['symbol'][0]
                                          : '?',
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
                                    stock['description'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFFB0B3B8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (price != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyProvider.formatCurrency(
                                      context,
                                      price,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (change != null)
                                    Text(
                                      '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: isUp
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFEF4444),
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
                  },
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const StockSearchSheet(),
                        );
                        _fetchQuotesAndProfiles();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.star_border, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Add to Wishlist',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SafeArea(top: false, child: SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
