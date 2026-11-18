import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../insights/object_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ObjectCategory? _filter;
  String _query = '';

  String _group(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Earlier this week';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final items = state.history.where((e) {
      if (_filter != null && e.cls.category != _filter) return false;
      if (_query.isNotEmpty && !e.cls.label.toLowerCase().contains(_query.toLowerCase())) return false;
      return true;
    }).toList();

    final rows = <Widget>[];
    String? current;
    var n = 0;
    for (final e in items) {
      final g = _group(e.time);
      if (g != current) {
        current = g;
        rows.add(Padding(
          key: ValueKey('h-$g'),
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
          child: Text(g.toUpperCase(), style: AppText.overline),
        ));
      }
      rows.add(FadeSlideIn(
        key: ValueKey(e.id),
        delay: Duration(milliseconds: n < 12 ? 40 * n : 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _HistoryTile(entry: e),
        ),
      ));
      n++;
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
          sliver: SliverList.list(children: [
            FadeSlideIn(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${state.history.length} DETECTIONS', style: AppText.overline),
                        const SizedBox(height: 4),
                        const Text('History', style: AppText.h1),
                      ],
                    ),
                  ),
                  if (state.history.isNotEmpty)
                    Pressable(
                      onTap: () => _confirmClear(context, state),
                      child: const GlassCard(
                        radius: 14,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.red),
                            SizedBox(width: 6),
                            Text('Clear', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: GlassCard(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: AppText.bodyStrong,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search objects',
                          hintStyle: TextStyle(color: AppColors.textFaint),
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ]),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    color: AppColors.violet,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final c in ObjectCategory.values)
                    _FilterChip(
                      label: c.label,
                      icon: c.icon,
                      color: c.color,
                      selected: _filter == c,
                      onTap: () => setState(() => _filter = c),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
            sliver: SliverList.list(children: rows),
          ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          tint: AppColors.surface,
          radius: 28,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(icon: Icons.delete_forever_rounded, color: AppColors.red, size: 56),
              const SizedBox(height: 16),
              const Text('Clear all history?', style: AppText.h2),
              const SizedBox(height: 8),
              const Text('This removes every saved detection from this device.',
                  textAlign: TextAlign.center, style: AppText.body),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => Navigator.pop(ctx, false),
                      child: const GlassCard(
                        radius: 18,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: Text('Cancel', style: AppText.bodyStrong)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlowButton(
                      label: 'Clear',
                      height: 52,
                      gradient: AppColors.sunsetGradient,
                      glowColor: AppColors.red,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) state.clearHistory();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: selected ? AppColors.accentGradient(color) : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: selected ? Colors.transparent : AppColors.stroke),
            boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: -4)] : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.bg : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.bg : AppColors.text,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = entry.cls.color;
    return Dismissible(
      key: ValueKey('d-${entry.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        final state = AppScope.read(context);
        final removed = state.removeEntry(entry.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceHigh,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Text('${entry.cls.label} removed', style: AppText.bodyStrong),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.cyan,
              onPressed: () {
                if (removed != null) state.restoreEntry(removed);
              },
            ),
          ));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [AppColors.red.withValues(alpha: 0), AppColors.red.withValues(alpha: 0.5)]),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Pressable(
        scale: 0.97,
        onTap: () => Navigator.of(context).push(PremiumRoute(
          builder: (_) => ObjectDetailScreen(cls: entry.cls, confidence: entry.confidence, mode: entry.mode),
        )),
        child: GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconBadge(icon: entry.cls.icon, color: c, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.cls.label, style: AppText.bodyStrong.copyWith(fontSize: 15.5))),
                        Text(clockTime(entry.time), style: AppText.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Pill(label: entry.mode.label, icon: entry.mode.icon, color: entry.mode.color, dense: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.confidence,
                              minHeight: 4,
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation(c),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(percent(entry.confidence), style: AppText.mono.copyWith(color: c)),
                      ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HologramOrb(size: 180, points: 140),
          SizedBox(height: 12),
          Text('Nothing here yet', style: AppText.h2),
          SizedBox(height: 6),
          Text('Captured detections will appear here.', style: AppText.body),
        ],
      ),
    );
  }
}
