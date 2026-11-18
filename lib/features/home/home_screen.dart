import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/effects.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';
import '../detect/live_detection_screen.dart';
import '../insights/object_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _heroBtn = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final top = MediaQuery.paddingOf(context).top;
    var i = 0;
    Duration d() => Duration(milliseconds: 80 * i++);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
          sliver: SliverList.list(children: [
            FadeSlideIn(delay: d(), child: const _Header()),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: d(),
              child: _HeroCard(
                buttonKey: _heroBtn,
                model: state.model,
                onStart: () => openScanner(context, centerOf(_heroBtn, context)),
              ),
            ),
            const SizedBox(height: 26),
            FadeSlideIn(delay: d(), child: const SectionHeader(title: 'Detection mode')),
            const SizedBox(height: 12),
          ]),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(delay: d(), child: _ModeSelector(state: state)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverList.list(children: [
            FadeSlideIn(delay: d(), child: _StatsRow(state: state)),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: d(),
              child: SectionHeader(
                title: 'Recent detections',
                action: 'See all',
                onAction: () => widget.onNavigate(1),
              ),
            ),
            const SizedBox(height: 6),
          ]),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(delay: d(), child: _RecentCarousel(state: state)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          sliver: SliverList.list(children: [
            FadeSlideIn(
              delay: d(),
              child: SectionHeader(
                title: 'Explore categories',
                action: 'Insights',
                onAction: () => widget.onNavigate(2),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(delay: d(), child: _CategoryGrid(state: state)),
          ]),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting(), style: AppText.caption.copyWith(fontSize: 13)),
              const SizedBox(height: 4),
              const GradientText('Ready to scan',
                  style: AppText.h1,
                  gradient: LinearGradient(colors: [Colors.white, Color(0xFFBFC8FF)])),
            ],
          ),
        ),
        Pressable(
          onTap: () {},
          child: GlassCard(
            radius: 16,
            padding: const EdgeInsets.all(11),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 22),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.pink, blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [AppColors.violet, AppColors.cyan, AppColors.mint, AppColors.violet]),
          ),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceHigh),
            child: const Icon(Icons.person_rounded, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.buttonKey, required this.onStart, required this.model});

  final GlobalKey buttonKey;
  final VoidCallback onStart;
  final DetectionModel model;

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      radius: 30,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: AppColors.heroGradient,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.35),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              const Positioned(
                right: -50,
                top: -40,
                child: IgnorePointer(child: HologramOrb(size: 250, points: 200)),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill(label: 'LIVE · ON-DEVICE', icon: Icons.bolt_rounded, color: AppColors.mint, dense: true),
                    const Spacer(),
                    const Text('Live object\ndetection', style: AppText.h1),
                    const SizedBox(height: 8),
                    Text(
                      '${model.title} · ${model.runtime}',
                      style: AppText.caption.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    GlowButton(
                      key: buttonKey,
                      label: 'Start scanning',
                      icon: Icons.center_focus_strong_rounded,
                      height: 52,
                      gradient: const LinearGradient(colors: [Colors.white, Color(0xFFDDE3FF)]),
                      glowColor: AppColors.cyan,
                      foreground: AppColors.bg,
                      onTap: onStart,
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

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: DetectionMode.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final m = DetectionMode.values[i];
          final selected = m == state.mode;
          return Pressable(
            onTap: () => state.setMode(m),
            child: AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.emphasized,
              width: selected ? 168 : 132,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [m.color.withValues(alpha: 0.34), m.color.withValues(alpha: 0.06)]
                      : [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.02)],
                ),
                border: Border.all(
                  color: selected ? m.color.withValues(alpha: 0.6) : AppColors.stroke,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: m.color.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 10))]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(icon: m.icon, color: m.color, size: 38, glow: selected),
                      const Spacer(),
                      AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: Motion.medium,
                        curve: Motion.overshoot,
                        child: Icon(Icons.check_circle_rounded, color: m.color, size: 20),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(m.label, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(m.tagline,
                      style: AppText.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, double value, IconData icon, Color color, {String suffix = '', int decimals = 0}) {
      return Expanded(
        child: GlassCard(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 14),
              AnimatedCounter(value: value, style: AppText.number.copyWith(fontSize: 24), suffix: suffix, decimals: decimals),
              const SizedBox(height: 2),
              Text(label, style: AppText.caption.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('Today', state.todayCount.toDouble(), Icons.today_rounded, AppColors.cyan),
        const SizedBox(width: 10),
        tile('Confidence', state.avgConfidence * 100, Icons.verified_rounded, AppColors.mint, suffix: '%'),
        const SizedBox(width: 10),
        tile('Classes', state.classesSeen.toDouble(), Icons.category_rounded, AppColors.amber),
      ],
    );
  }
}

class _RecentCarousel extends StatefulWidget {
  const _RecentCarousel({required this.state});
  final AppState state;

  @override
  State<_RecentCarousel> createState() => _RecentCarouselState();
}

class _RecentCarouselState extends State<_RecentCarousel> {
  final _pc = PageController(viewportFraction: 0.62);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.state.history.take(8).toList();
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No detections yet — start a scan.', style: AppText.body),
      );
    }
    return SizedBox(
      height: 226,
      child: PageView.builder(
        controller: _pc,
        itemCount: items.length,
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, i) => AnimatedBuilder(
          animation: _pc,
          builder: (context, child) {
            double page = 0;
            if (_pc.hasClients && _pc.position.haveDimensions) page = _pc.page ?? 0;
            final delta = (i - page).clamp(-1.5, 1.5);
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(-delta * 0.32),
              child: Transform.scale(
                scale: 1 - delta.abs() * 0.08,
                child: Opacity(opacity: (1 - delta.abs() * 0.35).clamp(0.0, 1.0), child: child),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6, top: 10, bottom: 10),
            child: _RecentCard(entry: items[i]),
          ),
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = entry.cls.color;
    return Pressable(
      onTap: () => Navigator.of(context).push(PremiumRoute(
        builder: (_) => ObjectDetailScreen(cls: entry.cls, confidence: entry.confidence, mode: entry.mode),
      )),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(AppColors.surfaceHigh, c, 0.28)!, AppColors.surface],
          ),
          border: Border.all(color: c.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.18), blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 12))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: entry.cls.icon, color: c, size: 46),
                const Spacer(),
                Pill(label: percent(entry.confidence), color: c, dense: true),
              ],
            ),
            const Spacer(),
            Text(entry.cls.label, style: AppText.h3),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(entry.mode.icon, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('${entry.mode.label} · ${timeAgo(entry.time)}',
                      style: AppText.caption.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: entry.confidence,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final counts = state.byCategory;
    final cats = ObjectCategory.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: cats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 112, // fixed height keeps content aligned on every width
      ),
      itemBuilder: (context, i) {
        final c = cats[i];
        return TiltCard(
          autoFloat: false,
          radius: 24,
          maxAngle: 0.22,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -14,
                  bottom: -18,
                  child: Icon(c.icon, size: 96, color: c.color.withValues(alpha: 0.10)),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(icon: c.icon, color: c.color, size: 36),
                      const Spacer(),
                      Text(c.label, style: AppText.bodyStrong),
                      Text('${counts[c]} detections', style: AppText.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
