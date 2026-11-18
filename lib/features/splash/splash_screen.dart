import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../widgets/effects.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  static const _title = 'LUMEN';
  static const _steps = [
    'Waking neural engine',
    'Loading detection model',
    'Calibrating camera pipeline',
    'Ready',
  ];

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PremiumRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _interval(double begin, double end, [Curve curve = Motion.emphasized]) =>
      curve.transform(((_c.value - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final orb = _interval(0.0, 0.45, Motion.overshoot);
            final spacing = 26 - 16 * _interval(0.2, 0.7);
            final tag = _interval(0.5, 0.75);
            final progress = _interval(0.25, 0.95, Curves.easeInOutCubic);
            final step = (progress * (_steps.length - 1)).round();
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: orb.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.4 + 0.6 * orb,
                          child: const HologramOrb(size: 250, speed: 1.6),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _title.length; i++)
                            _letter(i, spacing),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: tag,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - tag)),
                          child: Text(
                            'REAL-TIME OBJECT INTELLIGENCE',
                            style: AppText.overline.copyWith(
                                color: AppColors.textMuted, letterSpacing: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 48,
                  right: 48,
                  bottom: MediaQuery.paddingOf(context).bottom + 56,
                  child: Opacity(
                    opacity: _interval(0.25, 0.4),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: Motion.fast,
                          child: Text(
                            _steps[step],
                            key: ValueKey(step),
                            style: AppText.caption,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ProgressLine(progress),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _letter(int i, double spacing) {
    final start = 0.18 + i * 0.06;
    final v = _interval(start, start + 0.3);
    return Opacity(
      opacity: v,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.003)
          ..rotateX((1 - v) * 1.4),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: GradientLetter(_title[i]),
        ),
      ),
    );
  }
}

class GradientLetter extends StatelessWidget {
  const GradientLetter(this.char, {super.key});
  final String char;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFB9C3FF)],
      ).createShader(r),
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine(this.value);
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: AppColors.cyan.withValues(alpha: 0.7), blurRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}
