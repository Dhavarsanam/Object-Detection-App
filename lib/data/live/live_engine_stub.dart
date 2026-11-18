import '../models.dart';
import 'live_engine_result.dart';

/// Web / platforms without dart:ffi: TensorFlow Lite isn't available.
Future<LiveEngineResult> createLiveEngine({
  required DetectionMode mode,
  required double threshold,
  required int maxObjects,
  required bool useGpu,
}) async =>
    const LiveEngineResult.unavailable('Live camera runs on Android & iOS');
