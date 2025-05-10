import 'package:flutter/material.dart';

class AppThemeConfig {
  static ThemeData generateTheme({
    required Brightness brightness,
    required Color error,
    Iterable<ThemeExtension<dynamic>>? extensions,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme =
        isDark ? Typography.whiteMountainView : Typography.whiteMountainView;

    return ThemeData(
      brightness: brightness,
      extensions: extensions,
      textTheme: baseTextTheme,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.mintPrimary,
        brightness: brightness,
        primary: AppColors.primary,
        // secondary, tertiary & surface
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.mintDark : AppColors.mintDark.withAlpha(200),
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme => generateTheme(
    brightness: Brightness.dark,
    error: Colors.red,
    extensions: null,
  );

  static ThemeData get lightTheme => generateTheme(
    brightness: Brightness.light,
    error: Colors.red,
    extensions: null,
  );
}

class AppColors {
  // Mint color palette
  static const Color mintPrimary = Color(0xFF3EB489); // Medium mint
  static const Color mintLight = Color(0xFF98D8C8); // Light mint
  static const Color mintDark = Color(0xFF2A7F60); // Dark mint

  // Primary
  static const Color primary = Color(0xFF3EB489);
  static const Color primaryDark = Color(0xFF2A7F60);

  // Secondary
  static const Color secondary = Color(0xFF98D8C8);
  static const Color secondaryDark = Color(0xFF266B50);

  // Primary text
  static const Color primaryText = Colors.white;
  static const Color primaryDarkText = Colors.white;

  // Secondary text
  static const Color secondaryText = Color(0xFFBBF0DD);
  static const Color secondaryDarkText = Color(0xFFA9E6D0);

  // Surface colors (for cards, etc.)
  static const Color surfaceLight = Color(0xFF303030);
  static const Color surfaceDark = Color(0xFF121212);
}
