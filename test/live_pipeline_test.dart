import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/data/catalog.dart';
import 'package:project3/data/live/frame_converter.dart';
import 'package:project3/data/live/tracker.dart';
import 'package:project3/data/models.dart';

/// Builds a BGRA CameraImage where only source pixel (0,0) is red.
CameraImage _bgra(int w, int h) {
  final bytes = Uint8List(w * h * 4);
  bytes[2] = 255; // R of pixel (0,0); BGRA order
  bytes[3] = 255;
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData({
    'format': 1111970369, // kCVPixelFormatType_32BGRA
    'width': w,
    'height': h,
    'planes': [
      {'bytes': bytes, 'bytesPerRow': w * 4, 'bytesPerPixel': 4, 'width': w, 'height': h},
    ],
  });
}

bool _isRed(Uint8List rgb, int size, int x, int y) => rgb[(y * size + x) * 3] == 255;

void main() {
  group('frame converter', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('no rotation keeps top-left', () {
      final rgb = convertCameraImage(_bgra(4, 4), rotation: 0, size: 4);
      expect(_isRed(rgb, 4, 0, 0), isTrue);
    });

    test('90° moves sensor top-left to upright top-right', () {
      final rgb = convertCameraImage(_bgra(4, 2), rotation: 90, size: 2);
      expect(_isRed(rgb, 2, 1, 0), isTrue);
      expect(_isRed(rgb, 2, 0, 0), isFalse);
    });

    test('270° moves sensor top-left to upright bottom-left', () {
      final rgb = convertCameraImage(_bgra(2, 2), rotation: 270, size: 2);
      expect(_isRed(rgb, 2, 0, 1), isTrue);
    });
  });

  group('tracker', () {
    final person = classForLabel('person');

    test('keeps ID across frames and eases toward new box', () {
      final t = ObjectTracker();
      t.update([RawDetection(person, const Rect.fromLTWH(0.1, 0.1, 0.3, 0.5), 0.9)]);
      t.tick(0.1);
      final id = t.detections().single.trackId;

      t.update([RawDetection(person, const Rect.fromLTWH(0.14, 0.1, 0.3, 0.5), 0.88)]);
      t.tick(0.016);
      final d = t.detections().single;
      expect(d.trackId, id);
      expect(d.box.left, greaterThan(0.1));
      expect(d.box.left, lessThan(0.14));
    });

    test('drops tracks after they stop being seen', () {
      final t = ObjectTracker();
      t.update([RawDetection(person, const Rect.fromLTWH(0.1, 0.1, 0.3, 0.5), 0.9)]);
      for (var i = 0; i < 120; i++) {
        t.tick(1 / 60);
      }
      expect(t.detections(), isEmpty);
    });

    test('mirrors boxes for the front camera', () {
      final t = ObjectTracker();
      t.update([RawDetection(person, const Rect.fromLTRB(0.1, 0.2, 0.3, 0.6), 0.9)]);
      t.tick(0.1);
      final d = t.detections(mirror: true).single;
      expect(d.box.left, closeTo(0.7, 1e-9));
      expect(d.box.right, closeTo(0.9, 1e-9));
    });
  });

  test('COCO labels map to catalog or generated classes', () {
    expect(classForLabel('cell phone').id, 'phone');
    final truck = classForLabel('truck');
    expect(truck.category, ObjectCategory.vehicles);
    expect(truck.label, 'Truck');
    expect(truck.insights.length, DetectionMode.values.length);
    expect(identical(classForLabel('truck'), truck), isTrue);
  });
}
