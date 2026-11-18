import 'dart:math' as math;
import 'dart:ui';

import '../models.dart';

/// One model output, box normalised to the upright frame (0..1).
class RawDetection {
  const RawDetection(this.cls, this.box, this.score);
  final ObjectClass cls;
  final Rect box;
  final double score;
}

/// Lightweight IoU tracker.
///
/// Inference runs at ~10–30 Hz but the UI renders at 60+ Hz. The tracker
/// keeps stable IDs across frames, eases boxes toward each new measurement
/// and fades objects in/out so the overlay never flickers.
class ObjectTracker {
  final List<_Track> _tracks = [];
  int _nextId = 1;

  /// How long a track survives without a matching detection.
  static const keepAlive = 0.45;

  void update(List<RawDetection> dets) {
    final unmatched = List<_Track>.of(_tracks);
    final sorted = List<RawDetection>.of(dets)
      ..sort((a, b) => b.score.compareTo(a.score));
    for (final d in sorted) {
      _Track? best;
      var bestIou = 0.2;
      for (final t in unmatched) {
        if (t.cls.id != d.cls.id) continue;
        final v = iou(t.target, d.box);
        if (v > bestIou) {
          bestIou = v;
          best = t;
        }
      }
      if (best != null) {
        best
          ..target = d.box
          ..score = d.score
          ..sinceSeen = 0;
        unmatched.remove(best);
      } else {
        _tracks.add(_Track(_nextId++, d.cls, d.box, d.score));
      }
    }
  }

  void tick(double dt) {
    final k = 1 - math.exp(-dt * 14);
    final kv = 1 - math.exp(-dt * 9);
    for (final t in _tracks) {
      t.age += dt;
      t.sinceSeen += dt;
      t.shown = Rect.lerp(t.shown, t.target, k)!;
      t.shownScore += (t.score - t.shownScore) * k;
      final want = t.sinceSeen < keepAlive ? 1.0 : 0.0;
      t.visibility += (want - t.visibility) * kv;
    }
    _tracks.removeWhere((t) => t.sinceSeen > keepAlive && t.visibility < 0.03);
  }

  List<Detection> detections({
    bool Function(ObjectClass)? filter,
    int max = 10,
    bool mirror = false,
  }) {
    final list = _tracks
        .where((t) => t.visibility > 0.01 && (filter?.call(t.cls) ?? true))
        .toList()
      ..sort((a, b) => b.shownScore.compareTo(a.shownScore));
    return [
      for (final t in list.take(max))
        Detection(
          trackId: t.id,
          cls: t.cls,
          box: mirror
              ? Rect.fromLTRB(1 - t.shown.right, t.shown.top, 1 - t.shown.left, t.shown.bottom)
              : t.shown,
          confidence: t.shownScore,
          visibility: t.visibility.clamp(0.0, 1.0),
          age: t.age,
        ),
    ];
  }

  void clear() => _tracks.clear();

  static double iou(Rect a, Rect b) {
    final i = a.intersect(b);
    if (i.width <= 0 || i.height <= 0) return 0;
    final inter = i.width * i.height;
    return inter / (a.width * a.height + b.width * b.height - inter);
  }
}

class _Track {
  _Track(this.id, this.cls, Rect box, this.score)
      : target = box,
        shown = box,
        shownScore = score;

  final int id;
  final ObjectClass cls;
  Rect target;
  Rect shown;
  double score;
  double shownScore;
  double age = 0;
  double sinceSeen = 0;
  double visibility = 0;
}
