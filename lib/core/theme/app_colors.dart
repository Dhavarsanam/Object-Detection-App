import 'package:flutter/material.dart';

/// Lumen design tokens — a deep-space dark palette with electric accents.
abstract final class AppColors {
  // Surfaces
  static const bg = Color(0xFF05060B);
  static const bgElevated = Color(0xFF0A0C16);
  static const surface = Color(0xFF111425);
  static const surfaceHigh = Color(0xFF181C31);
  static const stroke = Color(0x1AFFFFFF);
  static const strokeStrong = Color(0x33FFFFFF);

  // Text
  static const text = Color(0xFFF3F5FF);
  static const textMuted = Color(0xFF8E95B0);
  static const textFaint = Color(0xFF545B78);

  // Accents
  static const violet = Color(0xFF7C5CFF);
  static const indigo = Color(0xFF4F46E5);
  static const cyan = Color(0xFF22D3EE);
  static const mint = Color(0xFF2EF2B5);
  static const pink = Color(0xFFFF4D9D);
  static const amber = Color(0xFFFFB547);
  static const red = Color(0xFFFF5A6E);
  static const lime = Color(0xFFC6F432);

  static const primaryGradient = LinearGradient(
    colors: [violet, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF2A1B78), Color(0xFF15154A), Color(0xFF0B2C4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const sunsetGradient = LinearGradient(
    colors: [pink, amber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient accentGradient(Color c) => LinearGradient(
        colors: [c, Color.lerp(c, Colors.white, 0.35)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
