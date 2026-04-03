import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 🇩🇿 Algerian Flag Colors
  static const Color primaryGreen = Color(0xFF006233);
  static const Color primaryRed = Color(0xFFD21034);
  static const Color white = Color(0xFFFFFFFF);

  // Green Shades
  static const Color greenLight = Color(0xFF00843D);
  static const Color greenDark = Color(0xFF004D26);
  static const Color greenSurface = Color(0xFFE8F5E9);
  static const Color greenAccent = Color(0xFF00C853);

  // Red Shades
  static const Color redLight = Color(0xFFE53950);
  static const Color redDark = Color(0xFFB00D28);
  static const Color redSurface = Color(0xFFFFEBEE);

  // Neutral Colors
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey900 = Color(0xFF212121);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey50 = Color(0xFFFAFAFA);

  // Background Colors - Green Theme
  static const Color background = Color(0xFF004D26); // Dark green background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground =
      Color(0xFF006233); // Primary green as scaffold

  // Text colors sémantiques
  /// Texte sur fond vert (scaffold, headers verts, AppBar)
  static const Color textOnGreen = Color(0xFFFFFFFF);
  /// Texte secondaire/caption sur fond vert (légèrement transparent)
  static const Color textOnGreenSecondary = Color(0xCCFFFFFF); // white 80%
  /// Texte principal sur fond blanc (cards, dialogs)
  static const Color textPrimary = Color(0xFF212121);   // grey900
  /// Texte secondaire sur fond blanc
  static const Color textSecondary = Color(0xFF616161); // grey700
  /// Texte tertiaire / hint sur fond blanc
  static const Color textHint = Color(0xFF9E9E9E);      // grey500

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFD21034);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Rating Colors
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF006233), // Green
    Color(0xFFD21034), // Red
    Color(0xFF1976D2), // Blue
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF00838F), // Teal
    Color(0xFFC2185B), // Pink
    Color(0xFF5D4037), // Brown
    Color(0xFF455A64), // Blue Grey
    Color(0xFF388E3C), // Light Green
    Color(0xFFE64A19), // Deep Orange
    Color(0xFF512DA8), // Deep Purple
  ];

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, greenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [primaryRed, redLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient algerianGradient = LinearGradient(
    colors: [primaryGreen, white, primaryRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
}
