import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils.dart';
import '../../widgets/effects.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion_widgets.dart';
import '../detect/live_detection_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../insights/insights_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _scanKey = GlobalKey();

  static const _items = [
    (Icons.space_dashboard_rounded, Icons.space_dashboard_outlined, 'Home'),
    (Icons.history_rounded, Icons.history_rounded, 'History'),
    (Icons.insights_rounded, Icons.insights_outlined, 'Insights'),
    (Icons.tune_rounded, Icons.tune_outlined, 'Settings'),
  ];

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _scan() {
    HapticFeedback.mediumImpact();
    openScanner(context, centerOf(_scanKey, context));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: _go),
      const HistoryScreen(),
      const InsightsScreen(),
      const SettingsScreen(),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground(intensity: 0.8)),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Motion.emphasized,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.97, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom + 14,
            child: _NavBar(
              index: _index,
              items: _items,
              onTap: _go,
              scanKey: _scanKey,
              onScan: _scan,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.items,
    required this.onTap,
    required this.scanKey,
    required this.onScan,
  });

  final int index;
  final List<(IconData, IconData, String)> items;
  final ValueChanged<int> onTap;
  final GlobalKey scanKey;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    // 5 slots — slot 2 is the scan button.
    final slot = index < 2 ? index : index + 1;
    return SizedBox(
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: 72,
            child: GlassCard(
              radius: 28,
              blur: 24,
              padding: EdgeInsets.zero,
              tint: AppColors.surface,
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 520),
                    curve: Motion.overshoot,
                    alignment: Alignment(-1 + slot * 0.5, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.2,
                      heightFactor: 1,
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.violet.withValues(alpha: 0.35),
                                AppColors.cyan.withValues(alpha: 0.08),
                              ],
                            ),
                            border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var s = 0; s < 5; s++)
                        Expanded(
                          child: s == 2
                              ? const SizedBox()
                              : _NavItem(
                                  item: items[s < 2 ? s : s - 1],
                                  selected: (s < 2 ? s : s - 1) == index,
                                  onTap: () => onTap(s < 2 ? s : s - 1),
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _ScanButton(key: scanKey, onTap: onScan),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.selected, required this.onTap});

  final (IconData, IconData, String) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      scale: 0.85,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              selected ? item.$1 : item.$2,
              key: ValueKey(selected),
              size: 23,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: Motion.fast,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textFaint,
            ),
            child: Text(item.$3),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      scale: 0.88,
      child: SizedBox(
        width: 88,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: -24,
              child: IgnorePointer(
                child: PulseRings(size: 110, color: AppColors.cyan, rings: 2),
              ),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [AppColors.violet, AppColors.cyan, AppColors.mint, AppColors.violet],
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.violet.withValues(alpha: 0.6), blurRadius: 24, offset: const Offset(0, 8)),
                  BoxShadow(color: AppColors.cyan.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: -6),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6D4BFF), Color(0xFF1AA9D6)],
                  ),
                ),
                child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
