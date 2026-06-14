import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Bleu royal (couleur principale)
  static const Color primaryBlue = Color(0xFF1A4DCC);

  // Bleu Klein (IKB) — fond pages auth & notifications
  static const Color kleinBlue = Color(0xFF002FA7);
  static const Color primaryBlueLight = Color(0xFF3B6FE5);
  static const Color primaryBlueDark = Color(0xFF1238A8);
  static const Color primaryBlueSurface = Color(0xFFEEF2FD);

  // Accent — Vert lime (accent secondaire)
  static const Color accentGreen = Color(0xFF70E010);
  static const Color accentGreenLight = Color(0xFF8AF535);
  static const Color accentGreenDark = Color(0xFF55B00A);
  static const Color accentGreenSurface = Color(0xFFF0FBE3);

  // Accent 2 — Orange (détail)
  static const Color accentOrange = Color(0xFFFF6530);
  static const Color accentOrangeLight = Color(0xFFFF8560);
  static const Color accentOrangeDark = Color(0xFFE04820);
  static const Color accentOrangeSurface = Color(0xFFFFF0EB);

  // Base
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);

  // Neutral Colors
  static const Color grey900 = Color(0xFF212121);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey50  = Color(0xFFFAFAFA);

  // Backgrounds — fond bleu marine
  static const Color scaffoldBackground = Color(0xFF002FA7); // bleu Klein (IKB)
  static const Color background         = Color(0xFF002FA7);
  static const Color surface            = Color(0xFF152238); // card légèrement plus claire
  static const Color surfaceVariant     = Color(0xFF1C2E4A); // card secondaire

  // Texte sémantique
  static const Color textOnPrimary          = Color(0xFFFFFFFF);
  static const Color textOnPrimarySecondary = Color(0xCCFFFFFF);
  static const Color textPrimary            = Color(0xFFEFF2F7); // blanc cassé sur fond sombre
  static const Color textSecondary          = Color(0xFFAAB4C8); // gris bleuté
  static const Color textHint               = Color(0xFF6B7A99);

  // Semantic Colors
  static const Color success      = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning      = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error        = Color(0xFFE53935);
  static const Color errorLight   = Color(0xFFFFEBEE);
  static const Color info         = Color(0xFF2196F3);
  static const Color infoLight    = Color(0xFFE3F2FD);

  // Rating Colors
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty  = Color(0xFFE0E0E0);

  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF1A4DCC), // Blue
    Color(0xFF70E010), // Lime green
    Color(0xFFFF6530), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF00838F), // Teal
    Color(0xFFC2185B), // Pink
    Color(0xFF5D4037), // Brown
    Color(0xFF455A64), // Blue Grey
    Color(0xFF388E3C), // Green
    Color(0xFFE64A19), // Deep Orange
    Color(0xFF512DA8), // Deep Purple
    Color(0xFF1976D2), // Light Blue
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentGreenDark, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryBlue, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Aliases pour compatibilité avec le code existant
  static const Color primaryGreen      = accentGreen;
  static const Color greenLight        = accentGreenLight;
  static const Color greenDark         = accentGreenDark;
  static const Color greenSurface      = accentGreenSurface;
  static const Color greenAccent       = accentGreen;
  static const Color primaryRed        = accentOrange;
  static const Color redLight          = accentOrangeLight;
  static const Color redDark           = accentOrangeDark;
  static const Color redSurface        = accentOrangeSurface;
  static const Color textOnGreen       = textOnPrimary;
  static const Color textOnGreenSecondary = textOnPrimarySecondary;
}
