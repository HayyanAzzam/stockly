import 'package:flutter/material.dart';

class SubscriptionPage extends StatefulWidget {
  final bool yearly;
  final VoidCallback? onProUpgrade;
  const SubscriptionPage({Key? key, this.yearly = false, this.onProUpgrade})
    : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool yearly = false;

  @override
  void initState() {
    super.initState();
    yearly = widget.yearly;
  }

  @override
  Widget build(BuildContext context) {
    final price = yearly ? '\$119' : '\$12';
    final period = yearly ? 'Yearly' : 'Monthly';
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text(
          'Subscription',
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
                style: const TextStyle(
                  color: Colors.green,
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          if (widget.onProUpgrade != null)
                            widget.onProUpgrade!();
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: const Text(
                          'Buy Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    paymentOption('Visa / master card', Icons.credit_card),
                    paymentOption('Apple Pay', Icons.phone_iphone),
                    paymentOption('Google pay', Icons.android),
                    paymentOption('Bank Payment', Icons.account_balance),
                    paymentOption('Debit card', Icons.credit_card_outlined),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Read FAQ',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Contact Support',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

  Widget paymentOption(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
