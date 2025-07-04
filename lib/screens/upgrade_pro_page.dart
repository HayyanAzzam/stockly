import 'package:flutter/material.dart';
import 'subscription_page.dart';

class UpgradeProPage extends StatefulWidget {
  final bool yearly;
  final VoidCallback? onProUpgrade;
  const UpgradeProPage({Key? key, this.yearly = false, this.onProUpgrade})
    : super(key: key);

  @override
  State<UpgradeProPage> createState() => _UpgradeProPageState();
}

class _UpgradeProPageState extends State<UpgradeProPage> {
  bool yearly = false;

  @override
  void initState() {
    super.initState();
    yearly = widget.yearly;
  }

  @override
  Widget build(BuildContext context) {
    final price = yearly ? '\$119' : '\$12';
    final period = yearly ? 'per year' : 'per month';
    final priceColor = yearly ? Colors.green : Colors.white;
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: priceColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                period,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF23272A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...[
                      'Ad-free experience',
                      'Priority Support 24/7',
                      'Real-time alerts',
                      'Bitcoin',
                      'API Access',
                      'Team Collaboration',
                      'Advanced Analytics',
                      'Offline Mode',
                    ].map(
                      (feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              feature,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
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
                          backgroundColor: const Color(0xFFFFD600),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionPage(
                                yearly: yearly,
                                onProUpgrade: widget.onProUpgrade,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Upgrade Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '30-day money-back guarantee • Cancel anytime',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Monthly'),
                    selected: !yearly,
                    onSelected: (v) => setState(() => yearly = false),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Yearly'),
                    selected: yearly,
                    onSelected: (v) => setState(() => yearly = true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
