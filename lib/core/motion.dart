import 'package:flutter/animation.dart';

/// Motion tokens. Every animation in the app pulls from here so the
/// whole product moves with one consistent personality.
abstract final class Motion {
  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 360);
  static const slow = Duration(milliseconds: 650);
  static const lazy = Duration(milliseconds: 1100);

  /// Material 3 "emphasized" — fast out, very soft landing.
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const emphasizedAccel = Cubic(0.3, 0.0, 0.8, 0.15);
  static const smooth = Curves.easeOutCubic;
  static const bounce = Curves.elasticOut;
  static const overshoot = Cubic(0.34, 1.56, 0.64, 1.0);
}
