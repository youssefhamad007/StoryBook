import 'package:flutter/material.dart';

class AppColors {
  // Gradients
  static const Color gradientPink = Color(0xFFFFD6E8);
  static const Color gradientBlue = Color(0xFFC0E5FF);
  static const Color gradientMint = Color(0xFFC2F5E9);
  static const Color gradientPurple = Color(0xFFE5DEFF);

  // Core
  static const Color background = Color(0xFFFFF9F5);
  static const Color foreground = Color(0xFF2D1B69);
  static const Color card = Color(0xFFFFFFFF);

  // Brand
  static const Color primary = Color(0xFFFF6B8A);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFC0E5FF);
  static const Color secondaryForeground = Color(0xFF2D1B69);
  static const Color accent = Color(0xFFC2F5E9);
  static const Color accentForeground = Color(0xFF2D1B69);

  // Muted
  static const Color muted = Color(0xFFF0E8FF);
  static const Color mutedForeground = Color(0xFF8E7BAA);

  // Status
  static const Color destructive = Color(0xFFFF4757);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFFFD700);

  // Border
  static const Color border = Color(0xFFEDD9F5);
  static const Color input = Color(0xFFF5ECFF);

  // Cover palette for stories
  static const List<Color> coverColors = [
    Color(0xFFFFD6E8),
    Color(0xFFC0E5FF),
    Color(0xFFC2F5E9),
    Color(0xFFE5DEFF),
    Color(0xFFFFF3CD),
    Color(0xFFFFE0B2),
    Color(0xFFF8D7DA),
    Color(0xFFD1ECF1),
  ];

  static LinearGradient mainGradient() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientPink, gradientBlue, gradientMint],
      );

  static LinearGradient purpleGradient() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientPurple, gradientBlue, gradientPink],
      );

  static LinearGradient mintGradient() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientMint, Color(0xFFA8E6CF), gradientBlue],
      );
}
