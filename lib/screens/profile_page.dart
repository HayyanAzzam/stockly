import 'package:flutter/material.dart';
import 'home_page.dart';
import '../services/finnhub_service.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../state/app_state.dart';
import '../providers/portfolio_provider.dart';
import 'upgrade_pro_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool darkMode = true;
  final FinnhubService _finnhubService = FinnhubService();
  static final Set<String> _proUsers = {};

  String? _location;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _location =
                '${data['city']}, ${data['regionName']}, ${data['country']}';
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _location = null;
            _isLoadingLocation = false;
          });
        }
      } else {
        setState(() {
          _location = null;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _location = null;
        _isLoadingLocation = false;
      });
    }
  }

  void _onProUpgrade() {
    final email = UserSession.email ?? '';
    if (email.isNotEmpty) {
      setState(() {
        _proUsers.add(email);
      });
    }
  }

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
    final isProMember = email.isNotEmpty && _proUsers.contains(email);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isProMember
                              ? const Color(0xFF29543C)
                              : const Color(0xFFFFD600),
                          foregroundColor: isProMember
                              ? const Color(0xFF22C55E)
                              : Colors.black,
                          disabledBackgroundColor: isProMember
                              ? const Color(0xFF29543C)
                              : null,
                          disabledForegroundColor: isProMember
                              ? const Color(0xFF22C55E)
                              : null,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isProMember
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpgradeProPage(
                                      onProUpgrade: _onProUpgrade,
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          isProMember
                              ? 'You are a Pro Member!'
                              : 'Upgrade to Pro',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isProMember
                                ? const Color(0xFF22C55E)
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                              final oldRate = currencyProvider.exchangeRate;
                              currencyProvider.setCurrency(val);
                              final newRate = currencyProvider.exchangeRate;
                              final ratio = newRate / oldRate;
                              Provider.of<PortfolioProvider>(
                                context,
                                listen: false,
                              ).applyExchangeRateToCash(ratio);
                              await Provider.of<MarketProvider>(
                                context,
                                listen: false,
                              ).refreshMarketStocks(context);
                            }
                          },
                        ),
                      ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingLocation)
                        const Text(
                          'Loading location...',
                          style: TextStyle(color: Color(0xFFB0B3B8)),
                        )
                      else if (_location != null)
                        Text(
                          _location!,
                          style: const TextStyle(color: Color(0xFFB0B3B8)),
                        )
                      else
                        const Text(
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
