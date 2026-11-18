import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographic scale. Tight negative tracking on display sizes,
/// open tracking on overlines — the hallmark of premium UI.
abstract final class AppText {
  static const display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
    height: 1.05,
    color: AppColors.text,
  );
  static const h1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.1,
    height: 1.12,
    color: AppColors.text,
  );
  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.2,
    color: AppColors.text,
  );
  static const h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 14.5,
    height: 1.5,
    color: AppColors.textMuted,
  );
  static const bodyStrong = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
  static const overline = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: AppColors.textMuted,
  );
  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const number = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
