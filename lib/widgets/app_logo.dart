class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80.0});

  @override
  Widget build(BuildContext context) {
    // Using a placeholder as the real logo URL might not be available long-term
    return Image.network(
      'https://i.ibb.co/DHj727qh/logo.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.bar_chart, size: size),
    );
  }
}