import 'package:flutter_test/flutter_test.dart';
import 'package:project3/data/app_state.dart';
import 'package:project3/data/catalog.dart';
import 'package:project3/data/detection_engine.dart';
import 'package:project3/data/models.dart';

void main() {
  test('catalog covers every category', () {
    for (final c in ObjectCategory.values) {
      expect(kCatalog.any((o) => o.category == c), isTrue, reason: c.label);
    }
    for (final o in kCatalog) {
      expect(o.insights.length, DetectionMode.values.length, reason: o.id);
    }
  });

  test('seeded history produces sane stats', () {
    final s = AppState();
    expect(s.history, isNotEmpty);
    expect(s.avgConfidence, inInclusiveRange(0.6, 1.0));
    expect(s.last7Days.length, 7);
  });

  test('engine produces normalised, thresholded detections', () {
    final e = SimulatedDetectionEngine(
      mode: DetectionMode.general,
      threshold: 0.5,
      maxObjects: 4,
      baseLatency: 20,
    );
    for (var i = 0; i < 600; i++) {
      e.tick(1 / 60);
    }
    expect(e.detections, isNotEmpty);
    for (final d in e.detections) {
      expect(d.confidence, greaterThanOrEqualTo(0.5));
      expect(d.box.left, greaterThanOrEqualTo(0));
      expect(d.box.bottom, lessThanOrEqualTo(1));
    }
    e.setMode(DetectionMode.inventory);
    for (var i = 0; i < 600; i++) {
      e.tick(1 / 60);
    }
    expect(
      e.detections.every((d) => d.cls.category == ObjectCategory.everyday),
      isTrue,
    );
  });
}
