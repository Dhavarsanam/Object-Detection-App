import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion.dart';
import '../core/theme/app_colors.dart';

/// Springy press feedback: dips on touch, overshoots back on release.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? Motion.instant : const Duration(milliseconds: 520),
        curve: _down ? Curves.easeOut : Motion.bounce,
        child: widget.child,
      ),
    );
  }
}

/// Staggered entrance: fade + rise + de-scale after [delay].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
    this.duration = Motion.slow,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = Motion.emphasized.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offset),
            child: Transform.scale(scale: 0.97 + 0.03 * v, child: child),
          ),
        );
      },
    );
  }
}

/// 3D tilt-on-touch card with moving glare. Uses a [Listener] so it never
/// steals scroll gestures. Optionally "floats" on its own when idle.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.maxAngle = 0.16,
    this.radius = 28,
    this.autoFloat = true,
  });

  final Widget child;
  final double maxAngle;
  final double radius;
  final bool autoFloat;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with TickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  Offset _from = Offset.zero;
  bool _touching = false;

  late final AnimationController _spring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addListener(() {
      setState(() {
        _tilt = Offset.lerp(_from, Offset.zero, Motion.bounce.transform(_spring.value))!;
      });
    });

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void initState() {
    super.initState();
    if (widget.autoFloat) _float.repeat();
  }

  @override
  void dispose() {
    _spring.dispose();
    _float.dispose();
    super.dispose();
  }

  void _update(Offset local, Size size) {
    final dx = (local.dx / size.width) * 2 - 1;
    final dy = (local.dy / size.height) * 2 - 1;
    setState(() {
      _tilt = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  void _release() {
    _touching = false;
    _from = _tilt;
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Listener(
        onPointerDown: (e) {
          _touching = true;
          _spring.stop();
          _update(e.localPosition, context.size ?? constraints.biggest);
        },
        onPointerMove: (e) =>
            _update(e.localPosition, context.size ?? constraints.biggest),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedBuilder(
          animation: _float,
          child: widget.child,
          builder: (context, child) {
            final t = _float.value * math.pi * 2;
            final idle = widget.autoFloat && !_touching
                ? Offset(math.sin(t) * 0.35, math.cos(t) * 0.25)
                : Offset.zero;
            final tilt = _tilt + idle;
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX(-tilt.dy * widget.maxAngle)
              ..rotateY(tilt.dx * widget.maxAngle);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: Stack(
                // Pass the parent's constraints straight to the card so it
                // fills grid cells exactly and the glare layer lines up.
                fit: StackFit.passthrough,
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.radius),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(tilt.dx, tilt.dy),
                              radius: 1.1,
                              colors: [
                                Colors.white.withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

/// Number that counts up/down smoothly when its value changes.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 1400),
  });

  final double value;
  final TextStyle style;
  final String suffix;
  final int decimals;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, v, _) =>
          Text('${v.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}

/// Expanding, fading sonar rings.
class PulseRings extends StatefulWidget {
  const PulseRings({
    super.key,
    this.color = AppColors.cyan,
    this.size = 120,
    this.rings = 3,
    this.period = const Duration(milliseconds: 2400),
    this.child,
  });

  final Color color;
  final double size;
  final int rings;
  final Duration period;
  final Widget? child;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(
        painter: _RingsPainter(_c, widget.color, widget.rings),
        child: widget.child == null ? null : Center(child: widget.child),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.anim, this.color, this.rings) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;
  final int rings;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    for (var i = 0; i < rings; i++) {
      final t = (anim.value + i / rings) % 1.0;
      final r = maxR * (0.35 + 0.65 * Curves.easeOut.transform(t));
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: (1 - t) * 0.55);
      canvas.drawCircle(c, r, p);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => false;
}

/// Primary call-to-action: gradient pill, colored glow and a light sheen
/// that periodically sweeps across.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.gradient = AppColors.primaryGradient,
    this.glowColor = AppColors.violet,
    this.height = 56,
    this.expand = true,
    this.foreground = Colors.white,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final Color glowColor;
  final double height;
  final bool expand;
  final Color foreground;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height * 0.36);
    return Pressable(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        width: widget.expand ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: 0.5),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // top inner highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.height * 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _sheen,
                builder: (context, _) {
                  final t = (_sheen.value * 2.2).clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment(-2.4 + 4.8 * Motion.smooth.transform(t), 0),
                    child: Transform.rotate(
                      angle: 0.35,
                      child: Container(
                        width: 36,
                        height: widget.height * 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.foreground, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.foreground,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated neon toggle switch.
class NeonSwitch extends StatelessWidget {
  const NeonSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.color = AppColors.cyan,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.9,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value
              ? LinearGradient(colors: [color, Color.lerp(color, AppColors.violet, 0.6)!])
              : null,
          color: value ? null : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: value ? Colors.transparent : AppColors.stroke,
          ),
          boxShadow: value
              ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16, spreadRadius: -4)]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 450),
          curve: Motion.overshoot,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.text)),
        ),
        if (action != null)
          Pressable(
            onTap: onAction,
            child: Row(
              children: [
                Text(action!,
                    style: const TextStyle(
                        color: AppColors.cyan, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, color: AppColors.cyan, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
