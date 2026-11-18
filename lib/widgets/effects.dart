import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

// ============================================================================
// Aurora background — slow drifting light blobs + dot grid + vignette.
// ============================================================================

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, this.child, this.intensity = 1});

  final Widget? child;
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraPainter(_c, widget.intensity),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.anim, this.intensity) : super(repaint: anim);
  final Animation<double> anim;
  final double intensity;

  static const _blobs = [
    (AppColors.violet, 0.15, 0.10, 0.75, 0.0),
    (AppColors.cyan, 0.90, 0.30, 0.6, 1.7),
    (AppColors.indigo, 0.30, 0.75, 0.7, 3.1),
    (AppColors.pink, 0.85, 0.90, 0.45, 4.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.bg);

    final t = anim.value * math.pi * 2;
    for (final (color, x, y, r, phase) in _blobs) {
      final center = Offset(
        size.width * (x + 0.08 * math.sin(t + phase)),
        size.height * (y + 0.05 * math.cos(t * 0.8 + phase)),
      );
      final radius = size.width * r * (1 + 0.08 * math.sin(t * 1.3 + phase));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: 0.20 * intensity),
            color.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Faint dot grid for a "technical" texture.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.035);
    const gap = 26.0;
    for (var x = gap / 2; x < size.width; x += gap) {
      for (var y = gap / 2; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 0.8, dot);
      }
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => false;
}

// ============================================================================
// Hologram orb — a rotating 3D Fibonacci sphere of glowing points with
// orbit rings and a scanning band. Pure CustomPainter math, no assets.
// ============================================================================

class HologramOrb extends StatefulWidget {
  const HologramOrb({
    super.key,
    this.size = 220,
    this.colorA = AppColors.violet,
    this.colorB = AppColors.cyan,
    this.points = 260,
    this.speed = 1,
  });

  final double size;
  final Color colorA;
  final Color colorB;
  final int points;
  final double speed;

  @override
  State<HologramOrb> createState() => _HologramOrbState();
}

class _HologramOrbState extends State<HologramOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (14000 / widget.speed).round()),
  )..repeat();

  late final List<_V3> _pts = _fibonacci(widget.points);

  static List<_V3> _fibonacci(int n) {
    final golden = math.pi * (3 - math.sqrt(5));
    return List.generate(n, (i) {
      final y = 1 - (i / (n - 1)) * 2;
      final r = math.sqrt(1 - y * y);
      final th = golden * i;
      return _V3(math.cos(th) * r, y, math.sin(th) * r);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _OrbPainter(_c, _pts, widget.colorA, widget.colorB),
        ),
      ),
    );
  }
}

class _V3 {
  const _V3(this.x, this.y, this.z);
  final double x, y, z;
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.anim, this.pts, this.a, this.b) : super(repaint: anim);
  final Animation<double> anim;
  final List<_V3> pts;
  final Color a, b;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.shortestSide * 0.36;
    final t = anim.value * math.pi * 2;
    const tilt = -0.42;
    final cosT = math.cos(tilt), sinT = math.sin(tilt);
    final cosY = math.cos(t), sinY = math.sin(t);

    // Core glow
    canvas.drawCircle(
      c,
      R * 1.45,
      Paint()
        ..shader = RadialGradient(colors: [
          a.withValues(alpha: 0.35),
          b.withValues(alpha: 0.08),
          Colors.transparent,
        ], stops: const [0, 0.5, 1]).createShader(
            Rect.fromCircle(center: c, radius: R * 1.45)),
    );

    // Orbit rings (ellipses tilted)
    for (var i = 0; i < 3; i++) {
      final ringR = R * (1.18 + i * 0.16);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.35 + i * 0.5 + t * (i.isEven ? 0.15 : -0.1));
      final ring = Rect.fromCenter(
          center: Offset.zero, width: ringR * 2, height: ringR * 0.55);
      canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = SweepGradient(colors: [
            b.withValues(alpha: 0.0),
            b.withValues(alpha: 0.55),
            a.withValues(alpha: 0.0),
          ], transform: GradientRotation(t * 2 + i)).createShader(ring),
      );
      // satellite
      final sa = t * (1.4 + i * 0.4) + i * 2;
      final sp = Offset(math.cos(sa) * ringR, math.sin(sa) * ringR * 0.275);
      canvas.drawCircle(sp, 2.6, Paint()..color = Colors.white.withValues(alpha: 0.9));
      canvas.drawCircle(
          sp,
          7,
          Paint()
            ..color = b.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.restore();
    }

    // Scan band position (in sphere y-space)
    final scanY = math.sin(t * 2.0);

    // Points — sort back-to-front for correct layering
    final projected = <(double, Offset, double, double)>[];
    for (final p in pts) {
      // rotate Y
      final x1 = p.x * cosY - p.z * sinY;
      final z1 = p.x * sinY + p.z * cosY;
      // tilt X
      final y2 = p.y * cosT - z1 * sinT;
      final z2 = p.y * sinT + z1 * cosT;
      final persp = 2.6 / (2.6 - z2);
      final o = Offset(c.dx + x1 * R * persp, c.dy + y2 * R * persp);
      final depth = (z2 + 1) / 2; // 0 back .. 1 front
      final scan = math.max(0.0, 1 - (p.y - scanY).abs() * 6);
      projected.add((z2, o, depth, scan));
    }
    projected.sort((p, q) => p.$1.compareTo(q.$1));

    final paint = Paint();
    for (final (_, o, depth, scan) in projected) {
      final col = Color.lerp(a, b, depth)!;
      final alpha = 0.15 + 0.8 * depth;
      final r = 0.7 + 1.6 * depth + scan * 1.4;
      paint.color = Color.lerp(col, Colors.white, scan * 0.8)!
          .withValues(alpha: (alpha + scan * 0.5).clamp(0.0, 1.0));
      canvas.drawCircle(o, r, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => false;
}

// ============================================================================
// Extruded 3D icon — stacks depth layers along Z and rotates in perspective.
// Drag to spin; it eases back into an idle sway.
// ============================================================================

class Extruded3DIcon extends StatefulWidget {
  const Extruded3DIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 120,
    this.depth = 14,
  });

  final IconData icon;
  final Color color;
  final double size;
  final int depth;

  @override
  State<Extruded3DIcon> createState() => _Extruded3DIconState();
}

class _Extruded3DIconState extends State<Extruded3DIcon>
    with TickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  double _drag = 0;

  @override
  void dispose() {
    _c.dispose();
    _settleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) =>
          setState(() => _drag = (_drag + d.delta.dx * 0.012).clamp(-1.1, 1.1)),
      onHorizontalDragEnd: (_) => _settle(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * math.pi * 2;
          final ry = math.sin(t) * 0.65 + _drag;
          final rx = math.cos(t * 0.5) * 0.18 - 0.12;
          final layers = <Widget>[];
          for (var i = widget.depth; i >= 0; i--) {
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateX(rx)
              ..rotateY(ry);
            m.multiply(Matrix4.translationValues(0, 0, i * 1.6));
            final isFront = i == 0;
            final shade = 1 - i / widget.depth;
            layers.add(Transform(
              alignment: Alignment.center,
              transform: m,
              child: isFront
                  ? ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => LinearGradient(
                        begin: Alignment(-1 + ry, -1),
                        end: Alignment(1 + ry, 1),
                        colors: [
                          Colors.white,
                          Color.lerp(widget.color, Colors.white, 0.35)!,
                          widget.color,
                        ],
                      ).createShader(r),
                      child: Icon(widget.icon, size: widget.size),
                    )
                  : Icon(
                      widget.icon,
                      size: widget.size,
                      color: Color.lerp(
                          Colors.black, widget.color, 0.25 + 0.4 * shade),
                    ),
            ));
          }
          return SizedBox.square(
            dimension: widget.size * 1.4,
            child: Stack(alignment: Alignment.center, children: [
              // floor shadow
              Positioned(
                bottom: 0,
                child: Container(
                  width: widget.size * (0.8 - ry.abs() * 0.15),
                  height: widget.size * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.45),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              ...layers,
            ]),
          );
        },
      ),
    );
  }

  late final AnimationController _settleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..addListener(() {
      setState(() =>
          _drag = _settleFrom * (1 - Curves.elasticOut.transform(_settleCtrl.value)));
    });
  double _settleFrom = 0;

  void _settle() {
    _settleFrom = _drag;
    _settleCtrl.forward(from: 0);
  }
}

// ============================================================================
// Confidence ring — animated gradient arc with a glowing head.
// ============================================================================

class ConfidenceRing extends StatelessWidget {
  const ConfidenceRing({
    super.key,
    required this.value,
    this.size = 96,
    this.stroke = 9,
    this.color = AppColors.cyan,
    this.label = 'confidence',
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutExpo,
      builder: (context, v, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(v, stroke, color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(v * 100).round()}%',
                  style: TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppColors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (label.isNotEmpty)
                  Text(label.toUpperCase(),
                      style: TextStyle(
                          fontSize: size * 0.075,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color);
  final double v, stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2 + 2);
    canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Colors.white.withValues(alpha: 0.07));

    if (v <= 0) return;
    final sweep = math.pi * 2 * v;
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [AppColors.violet, color, Color.lerp(color, Colors.white, 0.3)!],
      stops: const [0, 0.6, 1],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 6
          ..strokeCap = StrokeCap.round
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..color = color.withValues(alpha: 0.5));
    canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = shader);

    final head = -math.pi / 2 + sweep;
    final hp = rect.center +
        Offset(math.cos(head), math.sin(head)) * (rect.width / 2);
    canvas.drawCircle(hp, stroke * 0.38, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}
