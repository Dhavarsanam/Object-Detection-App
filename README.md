# Lumen — Real-time Object Detection (Flutter frontend)

A premium, animation-rich Flutter app for real-time, on-device object detection.

- **Android / iOS:** live camera feed analyzed by a bundled **TensorFlow Lite
  SSD MobileNet v1 (COCO, 80 classes)** model on a background isolate.
- **Web / desktop / no camera / permission denied:** falls back automatically to
  a simulated engine ("Demo mode") so the whole UI still works.

UI effects use no third-party packages (CustomPainter, Matrix4 perspective,
BackdropFilter, ShaderMask). ML uses `camera` + `tflite_flutter`.

## Run

```bash
flutter pub get
flutter run
```

## Screens

| Screen | Highlights |
|---|---|
| Splash | 3D particle "hologram" sphere, letters flip in on X-axis, loading line |
| Onboarding | 3D cube page transition, parallax text, orbiting tags, live tracking demo, fanned 3D mode cards |
| Home | Touch-tilt hero card with glare, animated mode selector, count-up stats, 3D perspective carousel, tilt category grid |
| Live detection | Circular-reveal entry, synthetic camera scene, glowing corner-bracket boxes, scan sweep, HUD (FPS / latency), mode banners (Surveillance alert, Inventory tally, Accessibility direction + distance), shutter with flash, tool rail, 3D camera flip |
| Insight sheet | Glass bottom sheet: confidence ring, distance / position / frame-area, mode-specific insight |
| Object detail | Draggable extruded 3D icon on hologram orb, parallax hero, animated mode-insight tabs |
| History | Search, gradient filter chips, grouped timeline, swipe-to-delete with undo |
| Insights | Animated bar chart (tap to select), glowing donut, latency sparkline, top-objects bars |
| Settings | Model picker (TFLite SSD / EfficientDet / ML Kit), custom gradient slider, neon switches |

## Structure

```
lib/
  core/       theme tokens, motion curves, custom routes, utils
  data/       models, object catalog, AppState, DetectionEngine (simulated)
  widgets/    glass, motion widgets, 3D effects, brackets, sound wave
  features/   splash, onboarding, shell, home, detect, insights, history, settings
```

## ML pipeline

```
camera image stream (YUV420 / BGRA)
  → frame_converter.dart   rotate + resize + colour-convert to 300×300 RGB in one pass
  → tflite_detector.dart   SSD MobileNet on a background IsolateInterpreter (GPU delegate optional)
  → tracker.dart           IoU matching → stable IDs, eased boxes, fade in/out at 60 fps
  → DetectionEngine        mode filter + max objects → List<Detection> for the UI
```

| File | Role |
|---|---|
| `lib/data/detection_engine.dart` | `DetectionEngine` interface + `SimulatedDetectionEngine` |
| `lib/data/live/live_engine_io.dart` | `CameraDetectionEngine`: camera, torch, zoom, lens switch, lifecycle |
| `lib/data/live/live_engine_stub.dart` | Web fallback (selected by conditional import on `dart.library.ffi`) |
| `lib/data/catalog.dart` | `classForLabel` maps COCO labels to rich UI classes |
| `assets/models/` | `ssd_mobilenet_v1_coco.tflite` (quantized, 4 MB) + `coco_labels.txt` |

The model is the official TensorFlow Lite release
(`coco_ssd_mobilenet_v1_1.0_quant_2018_06_29`). To swap models, replace the
asset files; input size, quantization and output count are read from the model.

**Permissions:** `CAMERA` (Android manifest) and `NSCameraUsageDescription`
(iOS Info.plist) are configured. Frames never leave the device.

**Tests:** `flutter test` covers frame rotation, the tracker, label mapping and
the simulated engine.
