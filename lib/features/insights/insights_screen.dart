import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';
import 'object_detail_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final week = state.last7Days;
    final weekTotal = week.fold<int>(0, (a, b) => a + b);
    var i = 0;
    Duration d() => Duration(milliseconds: 70 * i++);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 140),
      children: [
        FadeSlideIn(
          delay: d(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ANALYTICS', style: AppText.overline),
              SizedBox(height: 4),
              Text('Insights', style: AppText.h1),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: d(),
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detections this week', style: AppText.caption),
                          const SizedBox(height: 4),
                          AnimatedCounter(value: weekTotal.toDouble(), style: AppText.number.copyWith(fontSize: 32)),
                        ],
                      ),
                    ),
                    const Pill(label: '+18% vs last week', icon: Icons.trending_up_rounded, color: AppColors.mint, dense: true),
                  ],
                ),
                const SizedBox(height: 18),
                _WeekBarChart(values: week),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(delay: d(), child: _CategoryDonut(counts: state.byCategory)),
        const SizedBox(height: 14),
        FadeSlideIn(delay: d(), child: _PerformanceCard(model: state.model)),
        const SizedBox(height: 24),
        FadeSlideIn(delay: d(), child: const SectionHeader(title: 'Top objects')),
        const SizedBox(height: 12),
        for (final (idx, e) in state.topObjects.take(6).indexed)
          FadeSlideIn(
            delay: Duration(milliseconds: 380 + idx * 60),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TopObjectRow(
                rank: idx + 1,
                cls: e.key,
                count: e.value,
                max: state.topObjects.first.value,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _WeekBarChart extends StatefulWidget {
  const _WeekBarChart({required this.values});
  final List<int> values;

  @override
  State<_WeekBarChart> createState() => _WeekBarChartState();
}

class _WeekBarChartState extends State<_WeekBarChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  int _selected = 6;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  List<String> get _labels {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return i == 6 ? 'Today' : _days[day.weekday - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: LayoutBuilder(builder: (context, c) {
        return GestureDetector(
          onTapDown: (d) {
            final i = (d.localPosition.dx / (c.maxWidth / 7)).floor().clamp(0, 6);
            HapticFeedback.selectionClick();
            setState(() => _selected = i);
          },
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              size: Size(c.maxWidth, 190),
              painter: _BarPainter(
                values: widget.values,
                labels: _labels,
                progress: _c.value,
                selected: _selected,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.values, required this.labels, required this.progress, required this.selected});
  final List<int> values;
  final List<String> labels;
  final double progress;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = math.max(1, values.reduce(math.max)).toDouble();
    const labelH = 24.0, bubbleH = 30.0;
    final chartH = size.height - labelH - bubbleH;
    final slot = size.width / values.length;
    final barW = slot * 0.46;

    // guide lines
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final y = bubbleH + chartH * g / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }

    for (var i = 0; i < values.length; i++) {
      final local = ((progress - i * 0.07) / 0.6).clamp(0.0, 1.0);
      final eased = Curves.easeOutBack.transform(local);
      final h = math.max(4.0, chartH * (values[i] / maxV) * eased);
      final cx = slot * i + slot / 2;
      final r = Rect.fromLTWH(cx - barW / 2, bubbleH + chartH - h, barW, h);
      final sel = i == selected;
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));

      if (sel) {
        canvas.drawRRect(
          rr.inflate(2),
          Paint()
            ..color = AppColors.cyan.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sel
                ? const [AppColors.cyan, AppColors.violet]
                : [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.05)],
          ).createShader(r),
      );

      // labels
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
            color: sel ? AppColors.text : AppColors.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - labelH + 8));

      if (sel && local > 0.5) {
        final vp = TextPainter(
          text: TextSpan(
            text: '${values[i]}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.bg),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final bw = vp.width + 16;
        final bubble = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, r.top - 16), width: bw, height: 22),
          const Radius.circular(8),
        );
        canvas.drawRRect(bubble, Paint()..color = Colors.white);
        vp.paint(canvas, Offset(cx - vp.width / 2, r.top - 16 - vp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress || old.selected != selected || old.values != values;
}

// ---------------------------------------------------------------------------

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({required this.counts});
  final Map<ObjectCategory, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return GlassCard(
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeOutQuart,
            builder: (context, v, _) => SizedBox.square(
              dimension: 132,
              child: CustomPaint(
                painter: _DonutPainter(counts, v),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(total * v).round()}', style: AppText.number),
                      const Text('TOTAL', style: AppText.overline),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('By category', style: AppText.h3),
                const SizedBox(height: 12),
                for (final c in ObjectCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c.color,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.6), blurRadius: 6)],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c.label, style: AppText.caption.copyWith(color: AppColors.text))),
                        Text(
                          total == 0 ? '0%' : '${(counts[c]! / total * 100).round()}%',
                          style: AppText.mono.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.counts, this.progress);
  final Map<ObjectCategory, int> counts;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final rect = (Offset.zero & size).deflate(10);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = Colors.white.withValues(alpha: 0.05),
    );
    if (total == 0) return;
    const gap = 0.07;
    var start = -math.pi / 2;
    final sweepTotal = math.pi * 2 * progress;
    for (final c in ObjectCategory.values) {
      final frac = counts[c]! / total;
      final sweep = math.max(0.0, sweepTotal * frac - gap);
      if (sweep > 0) {
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = c.color;
        canvas.drawArc(rect, start + gap / 2, sweep, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 18
              ..color = c.color.withValues(alpha: 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawArc(rect, start + gap / 2, sweep, false, p);
      }
      start += sweepTotal * frac;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.model});
  final DetectionModel model;

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(model.index + 3);
    final samples = List.generate(24, (i) => model.latencyMs + rng.nextInt(9) - 4.0);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.speed_rounded, color: AppColors.mint, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('On-device performance', style: AppText.h3),
                    Text('${model.title} · ${model.runtime}', style: AppText.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeInOutCubic,
            builder: (context, v, _) => SizedBox(
              height: 70,
              width: double.infinity,
              child: CustomPaint(painter: _SparkPainter(samples, v)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _kv('Latency', '${model.latencyMs} ms', AppColors.mint),
              _kv('Throughput', '30 FPS', AppColors.cyan),
              _kv('mAP', '${(model.accuracy * 100).round()}%', AppColors.violet),
              _kv('Size', model.size, AppColors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, Color c) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v, style: AppText.bodyStrong.copyWith(color: c, fontSize: 14)),
            const SizedBox(height: 2),
            Text(k, style: AppText.caption.copyWith(fontSize: 10.5)),
          ],
        ),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.samples, this.progress);
  final List<double> samples;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = samples.reduce(math.min) - 2;
    final maxV = samples.reduce(math.max) + 2;
    Offset pt(int i) => Offset(
          size.width * i / (samples.length - 1),
          size.height * (1 - (samples[i] - minV) / (maxV - minV)),
        );
    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < samples.length; i++) {
      final p0 = pt(i - 1), p1 = pt(i);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      line.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    line.lineTo(pt(samples.length - 1).dx, pt(samples.length - 1).dy);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -10, size.width * progress, size.height + 20));
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.mint.withValues(alpha: 0.28), AppColors.mint.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(colors: [AppColors.cyan, AppColors.mint]).createShader(Offset.zero & size),
    );
    canvas.restore();

    final headX = size.width * progress;
    final idx = ((samples.length - 1) * progress).round();
    final head = Offset(headX, pt(idx).dy);
    canvas.drawCircle(head, 7, Paint()..color = AppColors.mint.withValues(alpha: 0.3));
    canvas.drawCircle(head, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------

class _TopObjectRow extends StatelessWidget {
  const _TopObjectRow({required this.rank, required this.cls, required this.count, required this.max});
  final int rank;
  final ObjectClass cls;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context).push(PremiumRoute(
        builder: (_) => ObjectDetailScreen(cls: cls, confidence: 0.9, mode: DetectionMode.general),
      )),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text('$rank', style: AppText.mono.copyWith(color: AppColors.textMuted, fontSize: 13)),
            ),
            IconBadge(icon: cls.icon, color: cls.color, size: 40, glow: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(cls.label, style: AppText.bodyStrong)),
                      Text('$count', style: AppText.mono.copyWith(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: count / max),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient(cls.color),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [BoxShadow(color: cls.color.withValues(alpha: 0.5), blurRadius: 6)],
                          ),
                        ),
                      ),
                    ),
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
