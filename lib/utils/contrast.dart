class AppColors {
  static const Color brandGreen = Color(0xFF22c55e);
  static const Color brandRed = Color(0xFFef4444);
  static const Color brandAmber = Color(0xFFf59e0b);

  static const Color darkBg = Color(0xFF212529);
  static const Color darkBgSecondary = Color(0xFF343a40);
  static const Color darkText = Color(0xFFf8f9fa);
  static const Color darkTextSecondary = Color(0xFFadb5bd);

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightBgSecondary = Color(0xFFf8f9fa);
  static const Color lightText = Color(0xFF212529);
  static const Color lightTextSecondary = Color(0xFF6c757d);

  static Color getChangeColor(double change) =>
      change >= 0 ? brandGreen : brandRed;
}