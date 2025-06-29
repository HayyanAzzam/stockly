class MarketsView extends StatelessWidget {
  const MarketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(child: _SummaryCard(title: 'Portfolio Value', value: '\$115,320.45', change: '+2.5%', changeColor: AppColors.brandGreen)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryCard(title: 'Available Cash', value: '\$8,321.19')),
          ],
        ),
        const SizedBox(height: 24),

        // Market Indices
        Text('Market Indices', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final isPositive = index.isEven;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isPositive ? AppColors.brandGreen.withOpacity(0.1) : AppColors.brandRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(['S&P 500', 'NASDAQ', 'DOW J', 'RUSSEL'][index], style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isPositive ? '\$5,321' : '\$17,173', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Icon(isPositive ? BootstrapIcons.arrow_up_right : BootstrapIcons.arrow_down_left, size: 20)
                    ],
                  )
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Stocks Logos
        Text('Stocks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['AAPL', 'GOOGL', 'MSFT', 'NVDA', 'AMZN', 'TSLA']
              .map((ticker) => _StockLogo(ticker: ticker))
              .toList(),
        )

      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final Color? changeColor;

  const _SummaryCard({required this.title, required this.value, this.change, this.changeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (change != null)
            Text(change!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: changeColor, fontWeight: FontWeight.bold))
          else
            const SizedBox(height: 19), // for alignment
        ],
      ),
    );
  }
}

class _StockLogo extends StatelessWidget {
  final String ticker;
  const _StockLogo({required this.ticker});

  String getLogoUrl(String ticker) {
    final map = {
      'AAPL': 'https://i.ibb.co/Y4fYhPGt/apfel.png',
      'GOOGL': 'https://i.ibb.co/qYyvsYs3/google.png',
      'MSFT': 'https://i.ibb.co/r232vB4H/microsoft.png',
      'NVDA': 'https://i.ibb.co/cKKKvvD5/nvidia.png',
      'AMZN': 'https://i.ibb.co/TxzZ0fqQ/amazon.png',
      'TSLA': 'https://i.ibb.co/994Jc99/tesla.png'
    };
    return map[ticker] ?? 'https://placehold.co/40x40?text=${ticker[0]}';
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool needsInvert = ['AAPL', 'AMZN'].contains(ticker);
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16)
        ),
        child: CachedNetworkImage(
            imageUrl: getLogoUrl(ticker),
            width: 32,
            height: 32,
            color: isDark && needsInvert ? Colors.white : null,
            errorWidget: (context, url, error) => const Icon(Icons.business)
        )
    );
  }
}
