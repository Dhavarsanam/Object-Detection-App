import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models.dart';
import '../../widgets/effects.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';
import '../../widgets/sound_wave.dart';
import '../insights/object_detail_screen.dart';

Future<void> showInsightSheet(
  BuildContext context, {
  required Detection detection,
  required DetectionMode mode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => InsightSheet(detection: detection, mode: mode),
  );
}

class InsightSheet extends StatefulWidget {
  const InsightSheet({super.key, required this.detection, required this.mode});
  final Detection detection;
  final DetectionMode mode;

  @override
  State<InsightSheet> createState() => _InsightSheetState();
}

class _InsightSheetState extends State<InsightSheet> {
  bool _speaking = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.detection;
    final cls = d.cls;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final position = d.direction == 'ahead'
        ? 'Center'
        : d.direction.contains('left')
            ? 'Left'
            : 'Right';
    final coverage = (d.box.width * d.box.height * 100).round();

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom + 10),
      child: GlassCard(
        radius: 32,
        blur: 30,
        tint: AppColors.surface,
        borderColor: cls.color.withValues(alpha: 0.35),
        glow: cls.color,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            FadeSlideIn(
              child: Row(
                children: [
                  IconBadge(icon: cls.icon, color: cls.color, size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cls.label, style: AppText.h2),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          Pill(label: cls.category.label, color: cls.category.color, dense: true),
                          Pill(label: 'Track #${d.trackId.toString().padLeft(4, '0')}', color: AppColors.textMuted, dense: true),
                        ]),
                      ],
                    ),
                  ),
                  ConfidenceRing(value: d.confidence, size: 82, stroke: 7, color: cls.color, label: ''),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Row(
                children: [
                  _Metric(label: 'Distance', value: '~${d.distanceMeters.toStringAsFixed(1)} m', icon: Icons.straighten_rounded),
                  const SizedBox(width: 8),
                  _Metric(label: 'Position', value: position, icon: Icons.my_location_rounded),
                  const SizedBox(width: 8),
                  _Metric(label: 'Frame area', value: '$coverage%', icon: Icons.crop_free_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: widget.mode.color.withValues(alpha: 0.10),
                  border: Border.all(color: widget.mode.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.mode.icon, color: widget.mode.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.mode.label.toUpperCase()} INSIGHT',
                              style: AppText.overline.copyWith(color: widget.mode.color)),
                          const SizedBox(height: 4),
                          Text(cls.insights[widget.mode] ?? '', style: AppText.body.copyWith(color: AppColors.text)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: Text(cls.description, style: AppText.body),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => setState(() => _speaking = !_speaking),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        color: _speaking ? AppColors.amber.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
                        border: Border.all(color: _speaking ? AppColors.amber.withValues(alpha: 0.5) : AppColors.stroke),
                      ),
                      child: Row(
                        children: [
                          _speaking
                              ? const SoundWave(color: AppColors.amber)
                              : const Icon(Icons.volume_up_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(_speaking ? 'Speaking' : 'Read aloud', style: AppText.bodyStrong),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlowButton(
                      label: 'Full details',
                      icon: Icons.open_in_full_rounded,
                      height: 54,
                      gradient: AppColors.accentGradient(cls.color),
                      glowColor: cls.color,
                      foreground: AppColors.bg,
                      onTap: () {
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.push(PremiumRoute(
                          builder: (_) => ObjectDetailScreen(cls: cls, confidence: d.confidence, mode: widget.mode),
                        ));
                      },
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(value, style: AppText.bodyStrong.copyWith(fontSize: 15)),
            Text(label, style: AppText.caption.copyWith(fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}
