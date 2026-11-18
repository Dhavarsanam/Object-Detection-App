import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final top = MediaQuery.paddingOf(context).top;
    var i = 0;
    Duration d() => Duration(milliseconds: 60 * i++);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 140),
      children: [
        FadeSlideIn(
          delay: d(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PREFERENCES', style: AppText.overline),
              SizedBox(height: 4),
              Text('Settings', style: AppText.h1),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(delay: d(), child: const _ProfileCard()),
        const SizedBox(height: 26),
        FadeSlideIn(delay: d(), child: const _Label('Detection model')),
        for (final m in DetectionModel.values)
          FadeSlideIn(
            delay: d(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(
                opacity: m.bundled ? 1 : 0.55,
                child: _ModelCard(
                  model: m,
                  selected: s.model == m,
                  onTap: m.bundled ? () => s.update(() => s.model = m) : null,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        FadeSlideIn(delay: d(), child: const _Label('Sensitivity')),
        FadeSlideIn(
          delay: d(),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Confidence threshold', style: AppText.bodyStrong)),
                    AnimatedSwitcher(
                      duration: Motion.fast,
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Text(
                        '${(s.threshold * 100).round()}%',
                        key: ValueKey((s.threshold * 100).round()),
                        style: AppText.number.copyWith(fontSize: 20, color: AppColors.cyan),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Hide detections below this confidence score.', style: AppText.caption),
                const SizedBox(height: 8),
                _GradientSlider(
                  value: s.threshold,
                  min: 0.3,
                  max: 0.95,
                  onChanged: (v) => s.update(() => s.threshold = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Max objects per frame', style: AppText.bodyStrong)),
                    _Stepper(
                      value: s.maxObjects,
                      min: 1,
                      max: 8,
                      onChanged: (v) => s.update(() => s.maxObjects = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(delay: d(), child: const _Label('Experience')),
        FadeSlideIn(
          delay: d(),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _ToggleRow(
                  icon: Icons.label_rounded,
                  color: AppColors.violet,
                  title: 'Show labels',
                  subtitle: 'Class name and score above each box',
                  value: s.showLabels,
                  onChanged: (v) => s.update(() => s.showLabels = v),
                ),
                _ToggleRow(
                  icon: Icons.record_voice_over_rounded,
                  color: AppColors.amber,
                  title: 'Voice feedback',
                  subtitle: 'Announce objects in accessibility mode',
                  value: s.voice,
                  onChanged: (v) => s.update(() => s.voice = v),
                ),
                _ToggleRow(
                  icon: Icons.vibration_rounded,
                  color: AppColors.pink,
                  title: 'Haptics',
                  subtitle: 'Tactile feedback on capture and taps',
                  value: s.haptics,
                  onChanged: (v) => s.update(() => s.haptics = v),
                ),
                _ToggleRow(
                  icon: Icons.contrast_rounded,
                  color: AppColors.lime,
                  title: 'High-contrast boxes',
                  subtitle: 'Thicker, brighter outlines for low vision',
                  value: s.highContrast,
                  onChanged: (v) => s.update(() => s.highContrast = v),
                ),
                _ToggleRow(
                  icon: Icons.save_alt_rounded,
                  color: AppColors.mint,
                  title: 'Save captures',
                  subtitle: 'Store captured detections in history',
                  value: s.saveCaptures,
                  onChanged: (v) => s.update(() => s.saveCaptures = v),
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(delay: d(), child: const _Label('Performance')),
        FadeSlideIn(
          delay: d(),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _ToggleRow(
              icon: Icons.memory_rounded,
              color: AppColors.cyan,
              title: 'GPU delegate',
              subtitle: 'Hardware-accelerated inference',
              value: s.gpuDelegate,
              onChanged: (v) => s.update(() => s.gpuDelegate = v),
              last: true,
            ),
          ),
        ),
        const SizedBox(height: 30),
        FadeSlideIn(
          delay: d(),
          child: const Center(
            child: Column(
              children: [
                Text('Lumen 1.0.0', style: AppText.caption),
                SizedBox(height: 2),
                Text('All processing happens on your device', style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(), style: AppText.overline),
      );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      autoFloat: false,
      radius: 26,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: AppColors.heroGradient,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [AppColors.violet, AppColors.cyan, AppColors.mint, AppColors.violet]),
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceHigh),
                child: const Icon(Icons.person_rounded, size: 30),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guest user', style: AppText.h3),
                  SizedBox(height: 4),
                  Text('On-device · No sign-in', style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Pill(label: 'PRO', icon: Icons.auto_awesome_rounded, color: AppColors.amber, dense: true),
          ],
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model, required this.selected, required this.onTap});
  final DetectionModel model;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.stroke,
          boxShadow: selected
              ? [BoxShadow(color: AppColors.violet.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 10))]
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.5),
            color: selected ? const Color(0xFF12132B) : AppColors.bgElevated,
          ),
          child: Row(
            children: [
              IconBadge(
                icon: model == DetectionModel.mlKit ? Icons.local_fire_department_rounded : Icons.hub_rounded,
                color: model == DetectionModel.mlKit ? AppColors.amber : AppColors.cyan,
                size: 42,
                glow: selected,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.title,
                        style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${model.runtime} · ${model.size} · ~${model.latencyMs} ms',
                        style: AppText.caption.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Pill(
                      label: model.bundled ? 'ON DEVICE' : 'NOT INSTALLED',
                      icon: model.bundled ? Icons.check_rounded : Icons.cloud_download_outlined,
                      color: model.bundled ? AppColors.mint : AppColors.textMuted,
                      dense: true,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: Motion.medium,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.cyan : AppColors.strokeStrong, width: 2),
                ),
                padding: const EdgeInsets.all(3),
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: Motion.medium,
                  curve: Motion.overshoot,
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.stroke)),
      ),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 36, glow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyStrong),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          NeonSwitch(value: value, onChanged: onChanged, color: color),
        ],
      ),
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({required this.value, required this.min, required this.max, required this.onChanged});
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: LayoutBuilder(builder: (context, c) {
        final f = ((value - min) / (max - min)).clamp(0.0, 1.0);
        void set(double dx) {
          final nf = (dx / c.maxWidth).clamp(0.0, 1.0);
          final nv = min + (max - min) * nf;
          final stepped = (nv * 20).round() / 20;
          if (stepped != value) {
            HapticFeedback.selectionClick();
            onChanged(stepped);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => set(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              AnimatedContainer(
                duration: Motion.fast,
                width: c.maxWidth * f,
                height: 8,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
              AnimatedPositioned(
                duration: Motion.fast,
                left: (c.maxWidth * f - 13).clamp(0.0, c.maxWidth - 26),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.cyan, width: 3),
                    boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.6), blurRadius: 12)],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged});
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) => Pressable(
          onTap: enabled ? onTap : null,
          scale: 0.85,
          child: AnimatedOpacity(
            duration: Motion.fast,
            opacity: enabled ? 1 : 0.3,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Icon(icon, size: 18),
            ),
          ),
        );

    return Row(
      children: [
        btn(Icons.remove_rounded, value > min, () => onChanged(value - 1)),
        SizedBox(
          width: 40,
          child: AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (c, a) => SlideTransition(
              position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(a),
              child: FadeTransition(opacity: a, child: c),
            ),
            child: Text('$value', key: ValueKey(value), textAlign: TextAlign.center, style: AppText.h3),
          ),
        ),
        btn(Icons.add_rounded, value < max, () => onChanged(value + 1)),
      ],
    );
  }
}
