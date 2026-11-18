import '../detection_engine.dart';

/// Outcome of trying to start the camera + model pipeline.
class LiveEngineResult {
  const LiveEngineResult(DetectionEngine this.engine) : reason = null;
  const LiveEngineResult.unavailable(String this.reason) : engine = null;

  final DetectionEngine? engine;

  /// Why the live engine could not start (shown in the HUD as "Demo mode").
  final String? reason;
}
