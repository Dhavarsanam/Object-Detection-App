import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'motion.dart';

/// Fade + rise + subtle scale + de-blur. Used for most pushes.
class PremiumRoute<T> extends PageRouteBuilder<T> {
  PremiumRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 560),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Motion.emphasized,
              reverseCurve: Curves.easeInCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) {
                final v = curved.value;
                final blur = (1 - v) * 12;
                return Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 40),
                    child: Transform.scale(
                      scale: 0.95 + 0.05 * v,
                      child: blur > 0.3
                          ? ImageFiltered(
                              imageFilter:
                                  ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                              child: child,
                            )
                          : child,
                    ),
                  ),
                );
              },
            );
          },
        );
}

/// Circular reveal that expands from [origin] (global coordinates).
class CircularRevealRoute<T> extends PageRouteBuilder<T> {
  CircularRevealRoute({required WidgetBuilder builder, required Offset origin})
      : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) => ClipPath(
                clipper: _CircleClipper(origin, curved.value),
                child: child,
              ),
            );
          },
        );
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.origin, this.progress);
  final Offset origin;
  final double progress;

  @override
  Path getClip(Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxR = corners.map((c) => (c - origin).distance).reduce(math.max);
    return Path()
      ..addOval(Rect.fromCircle(center: origin, radius: maxR * progress));
  }

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.progress != progress || old.origin != origin;
}
