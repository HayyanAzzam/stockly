import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/portfolio_provider.dart';
import 'home_page.dart';
import '../providers/currency_provider.dart';
import '../services/finnhub_service.dart';
import '../providers/market_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FinnhubService _service = FinnhubService();
  Map<String, Map<String, dynamic>> _profiles = {};
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final symbols = cartProvider.items.map((e) => e.symbol).toSet().toList();
    setState(() => _loading = true);
    final Map<String, Map<String, dynamic>> profiles = {};
    for (final symbol in symbols) {
      profiles[symbol] = await _service.fetchCompanyProfile(symbol) ?? {};
    }
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        title: const Text(
          'Shopping Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cartProvider.items.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Your cart is empty',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF23272A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6B7280)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartProvider.items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Color(0xFF6B7280), height: 1),
                        itemBuilder: (context, index) {
                          final item = cartProvider.items[index];
                          final profile = _profiles[item.symbol] ?? {};
                          final logo = profile['logo'];
                          final name = profile['name'] ?? item.symbol;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: logo != null && logo != ''
                                  ? NetworkImage(logo)
                                  : null,
                              child: (logo == null || logo == '')
                                  ? Text(
                                      item.symbol.isNotEmpty
                                          ? item.symbol[0]
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              '${item.shares.toStringAsFixed(0)} shares @ ${CurrencyProvider.formatCurrency(context, item.price)}',
                              style: const TextStyle(color: Color(0xFFB0B3B8)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${CurrencyProvider.formatCurrency(context, item.total)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: () =>
                                      cartProvider.removeItem(item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${CurrencyProvider.formatCurrency(context, cartProvider.total)}',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: Color(0xFF6B7280)),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: cartProvider.items.isEmpty
                            ? null
                            : () {
                                final portfolioProvider =
                                    Provider.of<PortfolioProvider>(
                                      context,
                                      listen: false,
                                    );
                                final items = List<CartItem>.from(
                                  cartProvider.items,
                                );
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );

                                // Process all cart items
                                for (final item in items) {
                                  if (item.type == 'buy') {
                                    portfolioProvider.buyStock(
                                      item.symbol,
                                      item.price,
                                      item.shares,
                                      name: item.name,
                                      logo: null,
                                    );
                                  } else {
                                    portfolioProvider.sellStock(
                                      item.symbol,
                                      item.price,
                                      item.shares,
                                    );
                                  }
                                }

                                cartProvider.clear();

                                // Show success message only
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Checkout successful!'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              },
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
