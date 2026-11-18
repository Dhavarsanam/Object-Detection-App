import 'dart:math';

import 'package:flutter/widgets.dart';

import 'catalog.dart';
import 'models.dart';

/// Global UI state: settings + detection history.
class AppState extends ChangeNotifier {
  AppState() : history = _seedHistory();

  DetectionMode mode = DetectionMode.general;
  DetectionModel model = DetectionModel.ssdMobileNet;
  double threshold = 0.55;
  int maxObjects = 4;
  bool showLabels = true;
  bool haptics = true;
  bool voice = true;
  bool highContrast = false;
  bool gpuDelegate = true;
  bool saveCaptures = true;

  final List<HistoryEntry> history;
  int _nextId = 10000;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void setMode(DetectionMode m) => update(() => mode = m);

  void addCaptures(List<Detection> detections) {
    final now = DateTime.now();
    for (final d in detections) {
      history.insert(
        0,
        HistoryEntry(
          id: _nextId++,
          cls: d.cls,
          confidence: d.confidence,
          time: now,
          mode: mode,
        ),
      );
    }
    notifyListeners();
  }

  HistoryEntry? removeEntry(int id) {
    final i = history.indexWhere((e) => e.id == id);
    if (i < 0) return null;
    final e = history.removeAt(i);
    notifyListeners();
    return e;
  }

  void restoreEntry(HistoryEntry e) {
    history.add(e);
    history.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
  }

  void clearHistory() => update(history.clear);

  // ---- Derived stats -------------------------------------------------------

  int get todayCount {
    final now = DateTime.now();
    return history
        .where((e) =>
            e.time.year == now.year &&
            e.time.month == now.month &&
            e.time.day == now.day)
        .length;
  }

  double get avgConfidence => history.isEmpty
      ? 0
      : history.map((e) => e.confidence).reduce((a, b) => a + b) /
          history.length;

  int get classesSeen => history.map((e) => e.cls.id).toSet().length;

  Map<ObjectCategory, int> get byCategory {
    final m = {for (final c in ObjectCategory.values) c: 0};
    for (final e in history) {
      m[e.cls.category] = m[e.cls.category]! + 1;
    }
    return m;
  }

  /// Counts for the last 7 days, oldest first.
  List<int> get last7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = List<int>.filled(7, 0);
    for (final e in history) {
      final day = DateTime(e.time.year, e.time.month, e.time.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < 7) out[6 - diff]++;
    }
    return out;
  }

  List<MapEntry<ObjectClass, int>> get topObjects {
    final m = <String, int>{};
    for (final e in history) {
      m[e.cls.id] = (m[e.cls.id] ?? 0) + 1;
    }
    final list = m.entries
        .map((e) => MapEntry(catalogById(e.key), e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  static List<HistoryEntry> _seedHistory() {
    final rng = Random(7);
    final now = DateTime.now();
    final list = <HistoryEntry>[];
    var id = 1;
    for (var day = 0; day < 7; day++) {
      final count = 3 + rng.nextInt(7);
      for (var i = 0; i < count; i++) {
        final minutesBack = day * 1440 + 8 + rng.nextInt(day == 0 ? 400 : 1300);
        list.add(HistoryEntry(
          id: id++,
          cls: kCatalog[rng.nextInt(kCatalog.length)],
          confidence: 0.62 + rng.nextDouble() * 0.36,
          time: now.subtract(Duration(minutes: minutesBack)),
          mode: DetectionMode.values[rng.nextInt(DetectionMode.values.length)],
        ));
      }
    }
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState super.notifier, required super.child});

  /// Subscribe to changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
