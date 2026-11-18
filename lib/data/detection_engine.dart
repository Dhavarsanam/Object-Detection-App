import 'dart:math';

import 'package:flutter/widgets.dart';

import 'catalog.dart';
import 'models.dart';

/// Everything the detection UI consumes. Two implementations:
/// [SimulatedDetectionEngine] (demo / web / no camera) and the camera +
/// TensorFlow Lite engine in `live/live_engine_io.dart`.
abstract class DetectionEngine extends ChangeNotifier {
  DetectionEngine({
    required this.mode,
    required this.threshold,
    required this.maxObjects,
  });

  DetectionMode mode;
  double threshold;
  int maxObjects;

  bool paused = false;
  double fps = 30;
  int latencyMs = 20;

  List<Detection> get detections;

  /// True when detections come from a real camera + model.
  bool get isLive;

  /// Human-readable model name for the HUD.
  String get modelName;

  /// Called every display frame with the elapsed seconds.
  void tick(double dt);

  void setMode(DetectionMode m);

  /// Camera preview widget (live engines only).
  Widget? buildPreview() => null;

  /// Portrait size of the preview in logical units (live engines only).
  Size? get previewSize => null;

  Future<void> setTorch(bool on) async {}
  Future<void> setZoom(double zoom) async {}
  Future<void> switchCamera() async {}

  /// App went to background / came back.
  Future<void> suspend() async {}
  Future<void> resume() async {}

  /// Whether a detection class is relevant in the current mode.
  bool allowedInMode(ObjectClass c) => switch (mode) {
        DetectionMode.surveillance => c.category == ObjectCategory.people ||
            c.category == ObjectCategory.vehicles ||
            c.category == ObjectCategory.animals ||
            c.id == 'backpack',
        DetectionMode.inventory => c.category == ObjectCategory.everyday,
        DetectionMode.general || DetectionMode.accessibility => true,
      };
}

/// Frontend-only stand-in for the ML pipeline: realistic, smoothly tracked
/// fake detections so the UI works anywhere (web, desktop, emulators).
class SimulatedDetectionEngine extends DetectionEngine {
  SimulatedDetectionEngine({
    required super.mode,
    required super.threshold,
    required super.maxObjects,
    required this.baseLatency,
  });

  int baseLatency;

  @override
  bool get isLive => false;

  @override
  String get modelName => 'Demo engine';

  final _rng = Random();
  final List<_Track> _tracks = [];
  List<Detection> _detections = const [];
  @override
  List<Detection> get detections => _detections;

  int framesProcessed = 0;

  int _nextId = 1;
  double _time = 0;
  double _spawnCooldown = 0.4;
  double _statsTimer = 0;

  @override
  void tick(double dt) {
    if (paused) return;
    _time += dt;
    framesProcessed++;

    for (final t in _tracks) {
      t.age += dt;
    }
    _tracks.removeWhere((t) => t.age > t.life);

    _spawnCooldown -= dt;
    if (_tracks.length < min(maxObjects, 4) && _spawnCooldown <= 0) {
      _spawn();
      _spawnCooldown = 0.7 + _rng.nextDouble() * 1.5;
    }

    _statsTimer += dt;
    if (_statsTimer > 0.5) {
      _statsTimer = 0;
      fps = 28.5 + _rng.nextDouble() * 2.5;
      latencyMs = baseLatency - 3 + _rng.nextInt(7);
    }

    final out = <Detection>[];
    for (final t in _tracks) {
      final fadeIn = (t.age / 0.4).clamp(0.0, 1.0);
      final fadeOut = ((t.life - t.age) / 0.4).clamp(0.0, 1.0);
      final vis = min(fadeIn, fadeOut);
      final cx = t.cx + t.ax * sin(_time * t.speed + t.phase);
      final cy = t.cy + t.ay * cos(_time * t.speed * 0.8 + t.phase);
      final breathe = 1 + 0.025 * sin(_time * 2.2 + t.phase);
      var rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: t.w * breathe,
        height: t.h * breathe,
      );
      rect = Rect.fromLTRB(
        rect.left.clamp(0.02, 0.98),
        rect.top.clamp(0.02, 0.98),
        rect.right.clamp(0.02, 0.98),
        rect.bottom.clamp(0.02, 0.98),
      );
      final conf =
          (t.base + 0.03 * sin(_time * 3.1 + t.phase)).clamp(0.0, 0.995);
      if (conf >= threshold) {
        out.add(Detection(
          trackId: t.id,
          cls: t.cls,
          box: rect,
          confidence: conf,
          visibility: vis,
          age: t.age,
        ));
      }
    }
    _detections = out;
    notifyListeners();
  }

  @override
  void setMode(DetectionMode m) {
    mode = m;
    final pool = _pool().toSet();
    for (final t in _tracks) {
      if (!pool.contains(t.cls) && t.life - t.age > 0.4) {
        t.life = t.age + 0.4; // fade out gracefully
      }
    }
    _spawnCooldown = 0.25;
  }

  List<ObjectClass> _pool() => kCatalog.where(allowedInMode).toList();

  void _spawn() {
    final pool = _pool();
    final active = _tracks.map((t) => t.cls.id).toSet();
    final fresh = pool.where((c) => !active.contains(c.id)).toList();
    final source = fresh.isNotEmpty ? fresh : pool;
    final cls = source[_rng.nextInt(source.length)];

    // Normalised to a ~9:19.5 portrait frame, so heights look shorter here
    // than they appear on screen.
    final (w, h) = switch (cls.category) {
      ObjectCategory.people => (0.32, 0.36),
      ObjectCategory.vehicles => (0.56, 0.15),
      ObjectCategory.animals => (0.40, 0.15),
      ObjectCategory.everyday => (0.28, 0.13),
    };
    final s = 0.8 + _rng.nextDouble() * 0.35;

    // Find a spot that doesn't overlap existing tracks too much.
    var cx = 0.5, cy = 0.45;
    for (var attempt = 0; attempt < 12; attempt++) {
      cx = 0.22 + _rng.nextDouble() * 0.56;
      cy = 0.25 + _rng.nextDouble() * 0.42;
      final ok = _tracks.every(
          (t) => (Offset(t.cx, t.cy) - Offset(cx, cy)).distance > 0.28);
      if (ok) break;
    }

    _tracks.add(_Track(
      id: _nextId++,
      cls: cls,
      cx: cx,
      cy: cy,
      w: w * s,
      h: h * s,
      ax: 0.015 + _rng.nextDouble() * 0.045,
      ay: 0.008 + _rng.nextDouble() * 0.025,
      speed: 0.3 + _rng.nextDouble() * 0.5,
      phase: _rng.nextDouble() * pi * 2,
      life: 4.5 + _rng.nextDouble() * 5,
      base: 0.64 + _rng.nextDouble() * 0.33,
    ));
  }
}

class _Track {
  _Track({
    required this.id,
    required this.cls,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.ax,
    required this.ay,
    required this.speed,
    required this.phase,
    required this.life,
    required this.base,
  });

  final int id;
  final ObjectClass cls;
  final double cx, cy, w, h, ax, ay, speed, phase, base;
  double life;
  double age = 0;
}
