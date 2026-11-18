import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared corner-bracket renderer used by onboarding and the live overlay.
void paintBrackets(Canvas canvas, Rect r, Color color, double alpha,
    {double stroke = 3, bool selected = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
  canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: 0.08 * alpha));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: (selected ? 0.7 : 0.3) * alpha),
  );
  final len = math.min(r.width, r.height) * 0.22;
  final path = Path()
    ..moveTo(r.left, r.top + len)
    ..lineTo(r.left, r.top + 10)
    ..quadraticBezierTo(r.left, r.top, r.left + 10, r.top)
    ..lineTo(r.left + len, r.top)
    ..moveTo(r.right - len, r.top)
    ..lineTo(r.right - 10, r.top)
    ..quadraticBezierTo(r.right, r.top, r.right, r.top + 10)
    ..lineTo(r.right, r.top + len)
    ..moveTo(r.right, r.bottom - len)
    ..lineTo(r.right, r.bottom - 10)
    ..quadraticBezierTo(r.right, r.bottom, r.right - 10, r.bottom)
    ..lineTo(r.right - len, r.bottom)
    ..moveTo(r.left + len, r.bottom)
    ..lineTo(r.left + 10, r.bottom)
    ..quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - 10)
    ..lineTo(r.left, r.bottom - len);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(color, Colors.white, 0.2)!.withValues(alpha: alpha),
  );
}
