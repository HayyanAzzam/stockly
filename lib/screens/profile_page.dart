import 'package:flutter/material.dart';
import 'home_page.dart';
import '../services/finnhub_service.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../state/app_state.dart';
import '../providers/portfolio_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool darkMode = true;
  bool isLoadingRate = false;
  final FinnhubService _finnhubService = FinnhubService();

  @override
  Widget build(BuildContext context) {
    final username =
        (UserSession.username != null && UserSession.username!.isNotEmpty)
        ? UserSession.username![0].toUpperCase() +
              UserSession.username!.substring(1)
        : '';
    final email = UserSession.email ?? '';
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currency = currencyProvider.currency;
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        title: const Text(
          'Account Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F34),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFB0B3B8),
                      child: Text(
                        (UserSession.username?.isNotEmpty == true)
                            ? UserSession.username![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Color(0xFFB0B3B8),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Upgrade to Pro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dark Mode',
                          style: TextStyle(color: Colors.white),
                        ),
                        Switch(
                          value: darkMode,
                          onChanged: (val) {
                            setState(() => darkMode = val);
                          },
                          activeColor: const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Currency',
                          style: TextStyle(color: Colors.white),
                        ),
                        DropdownButton<String>(
                          value: currency,
                          dropdownColor: const Color(0xFF23272A),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: 'USD (\$)',
                              child: Text('USD (\$)'),
                            ),
                            DropdownMenuItem(
                              value: 'EUR (€)',
                              child: Text('EUR (€)'),
                            ),
                            DropdownMenuItem(
                              value: 'GBP (£)',
                              child: Text('GBP (£)'),
                            ),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() {
                                isLoadingRate = true;
                              });
                              final oldRate = currencyProvider.exchangeRate;
                              currencyProvider.setCurrency(val);
                              final newRate = currencyProvider.exchangeRate;
                              final ratio = newRate / oldRate;
                              Provider.of<PortfolioProvider>(
                                context,
                                listen: false,
                              ).applyExchangeRateToCash(ratio);
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                await Provider.of<MarketProvider>(
                                  context,
                                  listen: false,
                                ).refreshMarketStocks(context);
                                setState(() {
                                  isLoadingRate = false;
                                });
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (isLoadingRate)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Could not retrieve location.',
                        style: TextStyle(color: Color(0xFFB0B3B8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Log out: clear user session and go to welcome page
                    UserSession.username = null;
                    UserSession.email = null;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
