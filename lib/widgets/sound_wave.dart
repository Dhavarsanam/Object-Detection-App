import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Animated equaliser bars — used for "speaking" / voice feedback states.
class SoundWave extends StatefulWidget {
  const SoundWave({
    super.key,
    this.active = true,
    this.color = AppColors.amber,
    this.bars = 5,
    this.height = 18,
  });

  final bool active;
  final Color color;
  final int bars;
  final double height;

  @override
  State<SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(SoundWave old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.bars, (i) {
          final phase = _c.value * math.pi * 2 + i * 1.1;
          final f = widget.active ? 0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase)).abs() : 0.25;
          return Container(
            width: 3,
            height: widget.height * f,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 6)],
            ),
          );
        }),
      ),
    );
  }
}
