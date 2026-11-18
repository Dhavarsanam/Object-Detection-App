import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models.dart';
import '../../widgets/brackets.dart';
import '../../widgets/effects.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';
import '../shell/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    (
      'See the world,\nunderstood.',
      'Lumen recognises people, vehicles, animals and everyday objects in real time — entirely on your device.',
    ),
    (
      'Every object,\ntracked live.',
      'Precision bounding boxes, confidence scores and stable tracking IDs, rendered at 30 frames per second.',
    ),
    (
      'Built for every\nmission.',
      'Switch between surveillance, inventory and accessibility modes — each with its own tailored insights.',
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      PremiumRoute(builder: (_) => const MainShell()),
    );
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 700), curve: Motion.emphasized);
    }
  }

  double _delta(int index) {
    if (!_pc.hasClients || !_pc.position.haveDimensions) {
      return (index - _page).toDouble();
    }
    return index - (_pc.page ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBackground(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _pc,
                builder: (context, _) {
                  final d = _delta(i).clamp(-1.0, 1.0);
                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(-d * 1.05);
                  return Transform(
                    alignment: d < 0 ? Alignment.centerRight : Alignment.centerLeft,
                    transform: m,
                    child: Opacity(
                      opacity: (1 - d.abs() * 0.6).clamp(0.0, 1.0),
                      child: _OnboardPage(
                        index: i,
                        title: _pages[i].$1,
                        body: _pages[i].$2,
                        parallax: d,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: pad.top + 12,
              left: 24,
              right: 16,
              child: Row(
                children: [
                  const _Logo(),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: _page == _pages.length - 1 ? 0 : 1,
                    child: Pressable(
                      onTap: _finish,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Skip', style: AppText.bodyStrong),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: pad.bottom + 28,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: Motion.medium,
                        curve: Motion.emphasized,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: active ? AppColors.primaryGradient : null,
                          color: active ? null : Colors.white.withValues(alpha: 0.18),
                          boxShadow: active
                              ? [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.6), blurRadius: 12)]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  GlowButton(
                    label: _page == _pages.length - 1 ? 'Get started' : 'Continue',
                    icon: _page == _pages.length - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    onTap: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.5), blurRadius: 14)],
          ),
          child: const Icon(Icons.blur_on_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text('Lumen', style: AppText.h3),
      ],
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.index,
    required this.title,
    required this.body,
    required this.parallax,
  });

  final int index;
  final String title;
  final String body;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final illustration = switch (index) {
      0 => const _OrbIllustration(),
      1 => const _TrackingIllustration(),
      _ => const _ModesIllustration(),
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 70, 28, 170),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Transform.translate(
                offset: Offset(parallax * 120, 0),
                child: Center(child: illustration),
              ),
            ),
            Transform.translate(
              offset: Offset(parallax * 60, 0),
              child: Text(title, style: AppText.h1.copyWith(fontSize: 34)),
            ),
            const SizedBox(height: 14),
            Transform.translate(
              offset: Offset(parallax * 30, 0),
              child: Text(body, style: AppText.body.copyWith(fontSize: 15.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _OrbIllustration extends StatefulWidget {
  const _OrbIllustration();

  @override
  State<_OrbIllustration> createState() => _OrbIllustrationState();
}

class _OrbIllustrationState extends State<_OrbIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tags = [
      ('Person', '98%', AppColors.violet, Alignment(-0.95, -0.7)),
      ('Car', '94%', AppColors.cyan, Alignment(0.95, -0.3)),
      ('Dog', '91%', AppColors.amber, Alignment(-0.85, 0.65)),
      ('Laptop', '89%', AppColors.mint, Alignment(0.8, 0.8)),
    ];
    return SizedBox(
      width: 320,
      height: 320,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Stack(
          children: [
            const Center(child: HologramOrb(size: 280)),
            for (var i = 0; i < tags.length; i++)
              Align(
                alignment: tags[i].$4,
                child: Transform.translate(
                  offset: Offset(0, math.sin(_c.value * math.pi * 2 + i * 1.6) * 8),
                  child: _FloatingTag(tags[i].$1, tags[i].$2, tags[i].$3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      glow: color,
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value, style: AppText.mono.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TrackingIllustration extends StatefulWidget {
  const _TrackingIllustration();

  @override
  State<_TrackingIllustration> createState() => _TrackingIllustrationState();
}

class _TrackingIllustrationState extends State<_TrackingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.85,
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 32,
        child: LayoutBuilder(builder: (context, c) {
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * math.pi * 2;
              final w = c.maxWidth, h = c.maxHeight;
              final center = Offset(w * (0.5 + 0.18 * math.sin(t)), h * (0.48 + 0.1 * math.sin(t * 2)));
              final boxSize = Size(w * 0.46, h * 0.42);
              final rect = Rect.fromCenter(center: center, width: boxSize.width, height: boxSize.height);
              final conf = 0.93 + 0.04 * math.sin(t * 3);
              return Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _GridPainter(_c.value))),
                  Positioned.fromRect(
                    rect: rect,
                    child: Icon(Icons.pets_rounded,
                        size: boxSize.shortestSide * 0.7,
                        color: AppColors.amber.withValues(alpha: 0.35)),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _BracketPainter(rect, AppColors.amber))),
                  Positioned(
                    left: rect.left,
                    top: rect.top - 30,
                    child: _FloatingTag('Dog', '${(conf * 100).round()}%', AppColors.amber),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text('ID #0417 · ${(28 + 2 * math.sin(t * 5)).toStringAsFixed(1)} FPS',
                        style: AppText.mono.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const gap = 28.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final sy = size.height * ((t * 2) % 1.0);
    final r = Rect.fromLTWH(0, sy - 60, size.width, 60);
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.cyan.withValues(alpha: 0.18)],
        ).createShader(r),
    );
    canvas.drawLine(Offset(0, sy), Offset(size.width, sy),
        Paint()..color = AppColors.cyan.withValues(alpha: 0.6)..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.t != t;
}

class _BracketPainter extends CustomPainter {
  _BracketPainter(this.rect, this.color);
  final Rect rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintBrackets(canvas, rect, color, 1);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.rect != rect;
}

class _ModesIllustration extends StatefulWidget {
  const _ModesIllustration();

  @override
  State<_ModesIllustration> createState() => _ModesIllustrationState();
}

class _ModesIllustrationState extends State<_ModesIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const modes = [
      DetectionMode.surveillance,
      DetectionMode.inventory,
      DetectionMode.accessibility,
    ];
    return SizedBox(
      width: 320,
      height: 320,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * math.pi * 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final i in const [0, 2, 1]) // middle card painted last = on top
                Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateZ((i - 1) * 0.28 + math.sin(t + i) * 0.03)
                    ..rotateY((i - 1) * -0.35 + math.sin(t) * 0.12)
                    ..rotateX(0.12),
                  child: Transform.translate(
                    offset: Offset((i - 1) * 62.0, (i - 1).abs() * 18.0 + math.sin(t + i) * 6),
                    child: _ModeCard(modes[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard(this.mode);
  final DetectionMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.surfaceHigh, mode.color, 0.35)!,
            AppColors.surface,
          ],
        ),
        border: Border.all(color: mode.color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: mode.color.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: -6, offset: const Offset(0, 16)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: mode.icon, color: mode.color),
          const Spacer(),
          Text(mode.label, style: AppText.h3.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Text(mode.tagline, style: AppText.caption.copyWith(fontSize: 11), maxLines: 2),
        ],
      ),
    );
  }
}
