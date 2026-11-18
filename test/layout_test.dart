// Layout regression test: renders every screen at small, medium and large
// phone sizes and fails on any overflow / layout exception.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/core/theme/app_theme.dart';
import 'package:project3/data/app_state.dart';
import 'package:project3/data/catalog.dart';
import 'package:project3/data/detection_engine.dart';
import 'package:project3/data/models.dart';
import 'package:project3/features/detect/insight_sheet.dart';
import 'package:project3/features/detect/live_detection_screen.dart';
import 'package:project3/features/history/history_screen.dart';
import 'package:project3/features/home/home_screen.dart';
import 'package:project3/features/insights/insights_screen.dart';
import 'package:project3/features/insights/object_detail_screen.dart';
import 'package:project3/features/onboarding/onboarding_screen.dart';
import 'package:project3/features/settings/settings_screen.dart';
import 'package:project3/features/shell/main_shell.dart';
import 'package:project3/features/splash/splash_screen.dart';

import 'support/real_fonts.dart';

const sizes = {
  'small 320x640': Size(320, 640),
  'medium 360x780': Size(360, 780),
  'large 430x932': Size(430, 932),
};

Widget _host(Widget child, {AppState? state}) => AppScope(
      notifier: state ?? AppState(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        home: child,
      ),
    );

Future<void> _settle(WidgetTester t, [int ms = 2500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Collects layout errors with their source location instead of failing on
/// the first one, so a single run reports every misaligned widget.
Future<void> _check(WidgetTester t, Size size, Widget screen, {Future<void> Function()? then}) async {
  final errors = <String>[];
  final original = FlutterError.onError;
  FlutterError.onError = (d) {
    final text = d.toString();
    final where = RegExp(r'(lib/[\w/]+\.dart:\d+)').firstMatch(text)?.group(1) ?? '?';
    final what = RegExp(r'overflowed by [\d.]+ pixels on the \w+').firstMatch(text)?.group(0) ??
        d.exceptionAsString().split('\n').first;
    errors.add('$what @ $where');
  };
  try {
    await _render(t, size, screen, then);
  } finally {
    FlutterError.onError = original;
  }
  final unique = errors.toSet().toList();
  for (final e in unique) {
    // ignore: avoid_print
    print('LAYOUT: $e');
  }
  expect(unique, isEmpty);
}

Future<void> _render(WidgetTester t, Size size, Widget screen, Future<void> Function()? then) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  t.view.padding = const FakeViewPadding(top: 24, bottom: 16);
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(screen));
  await _settle(t);
  if (then != null) {
    await then();
    await _settle(t);
  }
  // Scroll every scrollable to the bottom to lay out off-screen content too.
  for (final s in find.byType(Scrollable).evaluate().toList()) {
    if (!s.mounted) continue;
    final st = (s as StatefulElement).state as ScrollableState;
    if (st.position.axis == Axis.vertical && st.position.maxScrollExtent > 0) {
      st.position.jumpTo(st.position.maxScrollExtent);
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  await _settle(t, 1500);
  // Drain repeating animations/timers.
  await t.pumpWidget(const SizedBox());
  await _settle(t, 4000);
}

void main() {
  setUpAll(loadRealFonts);

  for (final entry in sizes.entries) {
    final size = entry.value;
    group(entry.key, () {
      testWidgets('splash', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(_host(const SplashScreen()));
        await _settle(t, 2000);
        expect(t.takeException(), isNull);
        await _settle(t, 3000); // let it navigate to onboarding
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await _settle(t, 4000);
      });
      testWidgets('onboarding pages', (t) async {
        await _check(t, size, const OnboardingScreen(), then: () async {
          for (var p = 0; p < 2; p++) {
            await t.drag(find.byType(PageView), Offset(-size.width * 0.8, 0));
            await _settle(t, 1200);
            expect(t.takeException(), isNull);
          }
        });
      });
      testWidgets('shell + home', (t) async => _check(t, size, const MainShell()));
      testWidgets('home', (t) async => _check(t, size, Scaffold(body: HomeScreen(onNavigate: (_) {}))));
      testWidgets('history', (t) async => _check(t, size, const Scaffold(body: HistoryScreen())));
      testWidgets('insights', (t) async => _check(t, size, const Scaffold(body: InsightsScreen())));
      testWidgets('settings', (t) async => _check(t, size, const Scaffold(body: SettingsScreen())));
      testWidgets('object detail (long name)', (t) async => _check(
          t,
          size,
          ObjectDetailScreen(cls: classForLabel('potted plant'), confidence: 0.87, mode: DetectionMode.accessibility)));
      testWidgets('live detection (demo)', (t) async => _check(t, size, const LiveDetectionScreen()));
      for (final mode in DetectionMode.values) {
        testWidgets('insight sheet · ${mode.name}', (t) async {
          final d = Detection(
            trackId: 42,
            cls: classForLabel('potted plant'),
            box: const Rect.fromLTWH(0.1, 0.2, 0.5, 0.4),
            confidence: 0.91,
            visibility: 1,
            age: 3,
          );
          await _check(t, size, Scaffold(body: InsightSheet(detection: d, mode: mode)));
        });
      }
    });
  }

  // Keep the simulated engine referenced so tree-shaking of test deps is stable.
  test('engine type', () => expect(SimulatedDetectionEngine, isNotNull));
}
