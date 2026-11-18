import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../detection_engine.dart';
import '../models.dart';
import 'frame_converter.dart';
import 'live_engine_result.dart';
import 'tflite_detector.dart';
import 'tracker.dart';

Future<LiveEngineResult> createLiveEngine({
  required DetectionMode mode,
  required double threshold,
  required int maxObjects,
  required bool useGpu,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return const LiveEngineResult.unavailable('Live camera runs on Android & iOS');
  }
  TfliteDetector? detector;
  CameraDetectionEngine? engine;
  try {
    final cams = await availableCameras();
    if (cams.isEmpty) {
      return const LiveEngineResult.unavailable('No camera found on this device');
    }
    detector = await TfliteDetector.load(useGpu: useGpu);
    engine = CameraDetectionEngine._(
      cams,
      detector,
      mode: mode,
      threshold: threshold,
      maxObjects: maxObjects,
    );
    final back = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );
    await engine._open(back);
    return LiveEngineResult(engine);
  } on CameraException catch (e) {
    _cleanup(engine, detector);
    final denied = e.code.toLowerCase().contains('denied') ||
        e.code.toLowerCase().contains('restricted');
    return LiveEngineResult.unavailable(
        denied ? 'Camera permission denied' : 'Camera unavailable (${e.code})');
  } catch (e) {
    _cleanup(engine, detector);
    debugPrint('Live engine failed: $e');
    return const LiveEngineResult.unavailable('Could not start the detector');
  }
}

void _cleanup(CameraDetectionEngine? engine, TfliteDetector? detector) {
  if (engine != null) {
    engine.dispose();
  } else {
    detector?.close();
  }
}

/// Real pipeline: camera image stream → RGB 300×300 → TFLite (background
/// isolate) → IoU tracker → smoothed [Detection]s at display frame rate.
class CameraDetectionEngine extends DetectionEngine {
  CameraDetectionEngine._(
    this._cameras,
    this._detector, {
    required super.mode,
    required super.threshold,
    required super.maxObjects,
  });

  final List<CameraDescription> _cameras;
  final TfliteDetector _detector;
  final _tracker = ObjectTracker();

  CameraController? _controller;
  CameraDescription? _current;
  List<Detection> _detections = const [];
  bool _busy = false;
  bool _disposed = false;
  int _inferences = 0;
  double _fpsWindow = 0;

  @override
  bool get isLive => true;

  @override
  String get modelName =>
      _detector.usingGpu ? '${TfliteDetector.displayName} · GPU' : TfliteDetector.displayName;

  @override
  List<Detection> get detections => _detections;

  bool get _isFront => _current?.lensDirection == CameraLensDirection.front;

  Future<void> _open(CameraDescription cam) async {
    final c = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );
    await c.initialize();
    if (_disposed) {
      await c.dispose();
      return;
    }
    _controller = c;
    _current = cam;
    await c.startImageStream(_onFrame);
    _notify();
  }

  Future<void> _close() async {
    final c = _controller;
    _controller = null;
    _notify();
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    await c.dispose();
  }

  void _onFrame(CameraImage image) {
    if (_busy || paused || _disposed) return;
    _busy = true;
    _process(image);
  }

  Future<void> _process(CameraImage image) async {
    final sw = Stopwatch()..start();
    try {
      final rgb = convertCameraImage(
        image,
        rotation: _current?.sensorOrientation ?? 90,
        size: _detector.inputSize,
      );
      final raws = await _detector.detect(rgb, threshold: threshold);
      if (_disposed) return;
      _tracker.update(raws);
      latencyMs = sw.elapsedMilliseconds;
      _inferences++;
    } catch (e) {
      debugPrint('Inference error: $e');
    } finally {
      _busy = false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void tick(double dt) {
    if (paused || _disposed) return;
    _tracker.tick(dt);
    _fpsWindow += dt;
    if (_fpsWindow >= 1) {
      fps = _inferences / _fpsWindow;
      _inferences = 0;
      _fpsWindow = 0;
    }
    _detections = _tracker.detections(
      filter: allowedInMode,
      max: maxObjects,
      mirror: _isFront,
    );
    _notify();
  }

  @override
  void setMode(DetectionMode m) => mode = m;

  @override
  Widget? buildPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return null;
    return CameraPreview(c);
  }

  @override
  Size? get previewSize {
    final s = _controller?.value.previewSize;
    if (s == null) return null;
    // previewSize is reported in sensor (landscape) orientation.
    return Size(s.shortestSide, s.longestSide);
  }

  @override
  Future<void> setTorch(bool on) async {
    try {
      await _controller?.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } catch (_) {}
  }

  @override
  Future<void> setZoom(double zoom) async {
    final c = _controller;
    if (c == null) return;
    try {
      final min = await c.getMinZoomLevel();
      final max = await c.getMaxZoomLevel();
      await c.setZoomLevel(zoom.clamp(min, max));
    } catch (_) {}
  }

  @override
  Future<void> switchCamera() async {
    if (_cameras.length < 2 || _current == null) return;
    final want = _isFront ? CameraLensDirection.back : CameraLensDirection.front;
    final next = _cameras.firstWhere((c) => c.lensDirection == want, orElse: () => _current!);
    if (next == _current) return;
    await _close();
    _tracker.clear();
    await _open(next);
  }

  @override
  Future<void> suspend() => _close();

  @override
  Future<void> resume() async {
    if (_controller == null && _current != null && !_disposed) {
      await _open(_current!);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _close().whenComplete(_detector.close);
    super.dispose();
  }
}
