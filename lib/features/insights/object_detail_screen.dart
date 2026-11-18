import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/effects.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';
import '../../widgets/sound_wave.dart';

class ObjectDetailScreen extends StatefulWidget {
  const ObjectDetailScreen({
    super.key,
    required this.cls,
    required this.confidence,
    required this.mode,
  });

  final ObjectClass cls;
  final double confidence;
  final DetectionMode mode;

  @override
  State<ObjectDetailScreen> createState() => _ObjectDetailScreenState();
}

class _ObjectDetailScreenState extends State<ObjectDetailScreen> {
  late DetectionMode _tab = widget.mode;
  bool _speaking = false;
  bool _saved = false;
  final _scroll = ScrollController();
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _offset = _scroll.offset));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.cls;
    final pad = MediaQuery.paddingOf(context);
    final state = AppScope.of(context);
    final seen = state.history.where((e) => e.cls.id == cls.id).length;
    final heroShift = (_offset * 0.45).clamp(0.0, 200.0);
    final heroFade = (1 - _offset / 320).clamp(0.0, 1.0);

    return Scaffold(
      body: AuroraBackground(
        child: Stack(
          children: [
            // Ambient color wash for this class.
            Positioned(
              top: -120,
              left: -60,
              right: -60,
              height: 520,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [
                      cls.color.withValues(alpha: 0.35),
                      cls.color.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: pad.top + 340,
                    child: Transform.translate(
                      offset: Offset(0, heroShift),
                      child: Opacity(
                        opacity: heroFade,
                        child: Padding(
                          padding: EdgeInsets.only(top: pad.top + 40),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              HologramOrb(size: 300, colorA: cls.color, colorB: AppColors.cyan, points: 180),
                              Extruded3DIcon(icon: cls.icon, color: cls.color, size: 130),
                              Positioned(
                                bottom: 6,
                                child: Text('DRAG TO ROTATE',
                                    style: AppText.overline.copyWith(color: AppColors.textFaint, fontSize: 9)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, pad.bottom + 40),
                  sliver: SliverList.list(children: [
                    FadeSlideIn(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Pill(label: cls.category.label.toUpperCase(), icon: cls.category.icon, color: cls.color, dense: true),
                                const SizedBox(height: 10),
                                Text(cls.label, style: AppText.display),
                              ],
                            ),
                          ),
                          ConfidenceRing(value: widget.confidence, size: 92, color: cls.color),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Row(
                        children: [
                          _Stat(value: '$seen', label: 'Times seen', color: cls.color),
                          const SizedBox(width: 10),
                          _Stat(value: state.model.title.split(' ').first, label: 'Model', color: AppColors.cyan),
                          const SizedBox(width: 10),
                          _Stat(value: '${state.model.latencyMs} ms', label: 'Inference', color: AppColors.mint),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ABOUT', style: AppText.overline),
                            const SizedBox(height: 8),
                            Text(cls.description, style: AppText.body.copyWith(color: AppColors.text, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: _ModeInsights(
                        cls: cls,
                        tab: _tab,
                        onTab: (m) => setState(() => _tab = m),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        children: [
                          for (final f in cls.facts.entries)
                            GlassCard(
                              radius: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(f.key.toUpperCase(), style: AppText.overline.copyWith(fontSize: 9.5)),
                                  const SizedBox(height: 4),
                                  Text(f.value, style: AppText.bodyStrong, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 320),
                      child: Row(
                        children: [
                          Expanded(
                            child: Pressable(
                              onTap: () => setState(() => _speaking = !_speaking),
                              child: GlassCard(
                                radius: 20,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                borderColor: _speaking ? AppColors.amber.withValues(alpha: 0.5) : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _speaking
                                        ? const SoundWave(color: AppColors.amber)
                                        : const Icon(Icons.volume_up_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(_speaking ? 'Speaking…' : 'Read aloud', style: AppText.bodyStrong),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GlowButton(
                              label: _saved ? 'Saved' : 'Save',
                              icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                              gradient: AppColors.accentGradient(cls.color),
                              glowColor: cls.color,
                              foreground: AppColors.bg,
                              onTap: () => setState(() => _saved = !_saved),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            // Frosted header that fades in once content scrolls beneath it.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pad.top + 64,
              child: IgnorePointer(
                child: Opacity(
                  opacity: ((_offset - 200) / 100).clamp(0.0, 1.0),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.bg.withValues(alpha: 0.72),
                          border: const Border(bottom: BorderSide(color: AppColors.stroke)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: pad.top + 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: const GlassCard(
                      radius: 16,
                      padding: EdgeInsets.all(11),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: _offset > 300 ? 1 : 0,
                    child: Text(cls.label, style: AppText.h3),
                  ),
                  const Spacer(),
                  Pressable(
                    onTap: () {},
                    child: const GlassCard(
                      radius: 16,
                      padding: EdgeInsets.all(11),
                      child: Icon(Icons.ios_share_rounded, size: 18),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.h3.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: AppText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ModeInsights extends StatelessWidget {
  const _ModeInsights({required this.cls, required this.tab, required this.onTab});
  final ObjectClass cls;
  final DetectionMode tab;
  final ValueChanged<DetectionMode> onTab;

  @override
  Widget build(BuildContext context) {
    final modes = DetectionMode.values;
    final index = modes.indexOf(tab);
    return GlassCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth / modes.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 450),
                    curve: Motion.overshoot,
                    left: w * index,
                    width: w,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: tab.color.withValues(alpha: 0.2),
                        border: Border.all(color: tab.color.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final m in modes)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTab(m),
                            child: Center(
                              child: Icon(m.icon, size: 20, color: m == tab ? m.color : AppColors.textMuted),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            child: AnimatedSwitcher(
              duration: Motion.medium,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                  child: c,
                ),
              ),
              child: Column(
                key: ValueKey(tab),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tab.label.toUpperCase()} INSIGHT', style: AppText.overline.copyWith(color: tab.color)),
                  const SizedBox(height: 6),
                  Text(cls.insights[tab] ?? '', style: AppText.body.copyWith(color: AppColors.text, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
