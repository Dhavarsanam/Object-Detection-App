import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../widgets/brackets.dart';

double _frac(double v) => v - v.floorToDouble();

/// A stylised "synthetic camera" scene: lit room, perspective floor grid,
/// drifting dust particles and lens vignette. Replace with `CameraPreview`
/// when wiring a real camera — every overlay above it stays the same.
class SyntheticScenePainter extends CustomPainter {
  SyntheticScenePainter(this.anim, {this.bright = false}) : super(repaint: anim);

  final Animation<double> anim;
  final bool bright;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final t = anim.value;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1430), Color(0xFF080B1A), Color(0xFF04050A)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    void light(Offset c, double r, Color color, double a) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [color.withValues(alpha: a), color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final sway = math.sin(t * math.pi * 2);
    light(Offset(w * (0.22 + 0.03 * sway), h * 0.14), w * 0.8, const Color(0xFF4C3BB5), bright ? 0.55 : 0.35);
    light(Offset(w * 0.88, h * 0.36), w * 0.6, AppColors.cyan, bright ? 0.2 : 0.11);
    if (bright) light(Offset(w * 0.5, h * 0.45), w, Colors.white, 0.10);

    // Perspective floor grid
    final horizon = h * 0.6;
    final vp = Offset(w / 2, horizon);
    final grid = Paint()
      ..strokeWidth = 1
      ..color = AppColors.cyan.withValues(alpha: 0.07);
    for (var i = -12; i <= 12; i++) {
      canvas.drawLine(vp, Offset(w / 2 + i * w * 0.17, h), grid);
    }
    final shift = _frac(t * 6);
    for (var k = 0; k < 14; k++) {
      final f = (k + shift) / 14;
      final y = horizon + (h - horizon) * f * f;
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()
          ..strokeWidth = 1
          ..color = AppColors.cyan.withValues(alpha: 0.02 + 0.08 * f),
      );
    }
    // Back wall
    final wall = Paint()..color = Colors.white.withValues(alpha: 0.025);
    for (var i = 1; i < 10; i++) {
      canvas.drawLine(Offset(w * i / 10, 0), Offset(w * i / 10, horizon), wall);
    }
    canvas.drawLine(Offset(0, horizon), Offset(w, horizon),
        Paint()..color = AppColors.cyan.withValues(alpha: 0.12));

    // Dust particles
    final p = Paint();
    for (var i = 0; i < 34; i++) {
      final rx = _frac(math.sin(i * 12.9898) * 43758.5453);
      final ry = _frac(math.sin(i * 78.233) * 12543.123);
      final sp = 0.4 + _frac(math.sin(i * 3.7) * 999.0) * 1.2;
      final x = w * _frac(rx + 0.02 * math.sin(t * math.pi * 2 * sp + i));
      final y = h * _frac(ry - t * sp);
      final r = 0.8 + 2.4 * _frac(rx * 7.3);
      p.color = (i.isEven ? Colors.white : AppColors.cyan).withValues(alpha: 0.08 + 0.22 * _frac(ry * 5.1));
      canvas.drawCircle(Offset(x, y), r, p);
    }

    // Vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
          stops: const [0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(SyntheticScenePainter old) => old.bright != bright;
}

/// Sweeping scan line with a trailing glow band.
class ScanLinePainter extends CustomPainter {
  ScanLinePainter(this.anim, this.color) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final v = Curves.easeInOutSine.transform(anim.value);
    final y = size.height * (0.08 + 0.84 * v);
    final band = Rect.fromLTWH(0, y - 110, size.width, 110);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.13)],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..shader = LinearGradient(colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0),
        ]).createShader(Rect.fromLTWH(0, y, size.width, 1))
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(ScanLinePainter old) => old.color != color;
}

/// Large L-shaped viewfinder corners framing the screen.
class FrameCornersPainter extends CustomPainter {
  FrameCornersPainter(this.insets);
  final EdgeInsets insets;

  @override
  void paint(Canvas canvas, Size size) {
    final r = insets.deflateRect(Offset.zero & size);
    const l = 34.0;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.3);
    final path = Path()
      ..moveTo(r.left, r.top + l)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + l, r.top)
      ..moveTo(r.right - l, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + l)
      ..moveTo(r.right, r.bottom - l)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right - l, r.bottom)
      ..moveTo(r.left + l, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.bottom - l);
    canvas.drawPath(path, p);
    // center cross
    final c = r.center;
    final cp = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawLine(c.translate(-10, 0), c.translate(10, 0), cp);
    canvas.drawLine(c.translate(0, -10), c.translate(0, 10), cp);
  }

  @override
  bool shouldRepaint(FrameCornersPainter old) => old.insets != insets;
}

/// All bounding boxes for one frame.
class BoxesPainter extends CustomPainter {
  BoxesPainter({
    required this.detections,
    required this.selected,
    required this.highContrast,
    required this.pulse,
  }) : super(repaint: pulse);

  final List<Detection> detections;
  final int? selected;
  final bool highContrast;
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final r = Rect.fromLTRB(
        d.box.left * size.width,
        d.box.top * size.height,
        d.box.right * size.width,
        d.box.bottom * size.height,
      );
      final color = highContrast ? AppColors.lime : d.cls.color;
      final isSel = d.trackId == selected;
      paintBrackets(canvas, r, color, d.visibility,
          stroke: highContrast ? 4 : 3, selected: isSel);

      if (isSel) {
        final pv = pulse.value;
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.inflate(4 + pv * 10), const Radius.circular(18)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = color.withValues(alpha: 0.5 * (1 - pv) * d.visibility),
        );
      }

      // center reticle
      final c = r.center;
      final cp = Paint()
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.6 * d.visibility);
      canvas.drawLine(c.translate(-6, 0), c.translate(6, 0), cp);
      canvas.drawLine(c.translate(0, -6), c.translate(0, 6), cp);
    }
  }

  @override
  bool shouldRepaint(BoxesPainter old) => true;
}

/// Rotating dashed "searching" reticle shown when nothing is detected.
class SearchReticlePainter extends CustomPainter {
  SearchReticlePainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    final rot = anim.value * math.pi * 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const segs = 4;
    for (var i = 0; i < segs; i++) {
      final start = rot + i * math.pi * 2 / segs;
      p.color = (i.isEven ? AppColors.cyan : AppColors.violet).withValues(alpha: 0.8);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, 0.9, false, p);
    }
    p
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.25);
    for (var i = 0; i < 24; i++) {
      final a = -rot * 0.6 + i * math.pi * 2 / 24;
      final o1 = c + Offset(math.cos(a), math.sin(a)) * (r * 0.72);
      final o2 = c + Offset(math.cos(a), math.sin(a)) * (r * (i % 6 == 0 ? 0.6 : 0.67));
      canvas.drawLine(o1, o2, p);
    }
    canvas.drawCircle(c, 3, Paint()..color = AppColors.cyan);
  }

  @override
  bool shouldRepaint(SearchReticlePainter old) => false;
}
