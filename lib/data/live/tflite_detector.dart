import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../catalog.dart';
import 'tracker.dart';

/// Wraps the bundled SSD MobileNet v1 (COCO, 90 classes) TFLite model.
///
/// Inference runs on a background isolate via [IsolateInterpreter], so the
/// UI thread only pays for frame conversion.
class TfliteDetector {
  TfliteDetector._(
    this._interpreter,
    this._isolate,
    this._labels,
    this._labelOffset,
    this.inputSize,
    this.isQuantized,
    this.maxResults,
  );

  static const modelAsset = 'assets/models/ssd_mobilenet_v1_coco.tflite';
  static const labelsAsset = 'assets/models/coco_labels.txt';
  static const displayName = 'SSD MobileNet v1 · COCO';

  final Interpreter _interpreter;
  final IsolateInterpreter _isolate;
  final List<String> _labels;
  final int _labelOffset;
  final int inputSize;
  final bool isQuantized;
  final int maxResults;

  /// True when the GPU delegate was requested and accepted.
  bool usingGpu = false;

  static Future<Interpreter> _create(bool gpu) {
    final options = InterpreterOptions()..threads = 4;
    if (gpu) {
      options.addDelegate(Platform.isIOS ? GpuDelegate() : GpuDelegateV2());
    }
    return Interpreter.fromAsset(modelAsset, options: options);
  }

  static Future<TfliteDetector> load({bool useGpu = false}) async {
    Interpreter interpreter;
    var gpuOk = false;
    if (useGpu) {
      try {
        interpreter = await _create(true);
        gpuOk = true;
      } catch (_) {
        // GPU delegate unsupported on this device — fall back to CPU.
        interpreter = await _create(false);
      }
    } else {
      interpreter = await _create(false);
    }
    final input = interpreter.getInputTensor(0);
    final labels = (await rootBundle.loadString(labelsAsset))
        .split('\n')
        .map((l) => l.trim())
        .toList();
    while (labels.isNotEmpty && labels.last.isEmpty) {
      labels.removeLast();
    }
    final isolate = await IsolateInterpreter.create(address: interpreter.address);
    return TfliteDetector._(
      interpreter,
      isolate,
      labels,
      labels.isNotEmpty && labels.first == '???' ? 1 : 0,
      input.shape[1],
      input.type == TensorType.uint8,
      interpreter.getOutputTensor(0).shape[1],
    )..usingGpu = gpuOk;
  }

  /// [rgb] is an upright `inputSize × inputSize × 3` RGB888 buffer.
  Future<List<RawDetection>> detect(Uint8List rgb, {required double threshold}) async {
    final Object input;
    if (isQuantized) {
      input = rgb;
    } else {
      final f = Float32List(rgb.length);
      for (var i = 0; i < rgb.length; i++) {
        f[i] = (rgb[i] - 127.5) / 127.5;
      }
      input = f.buffer.asUint8List();
    }

    final boxes = Float32List(maxResults * 4);
    final classes = Float32List(maxResults);
    final scores = Float32List(maxResults);
    final count = Float32List(1);
    await _isolate.runForMultipleInputs([input], {
      0: boxes.buffer,
      1: classes.buffer,
      2: scores.buffer,
      3: count.buffer,
    });

    final n = count[0].round().clamp(0, maxResults);
    final out = <RawDetection>[];
    for (var i = 0; i < n; i++) {
      final score = scores[i];
      if (score < threshold) continue;
      final li = classes[i].round() + _labelOffset;
      if (li < 0 || li >= _labels.length) continue;
      final label = _labels[li];
      if (label.isEmpty || label == '???') continue;
      // SSD box order: ymin, xmin, ymax, xmax (normalised).
      final box = Rect.fromLTRB(
        boxes[i * 4 + 1].clamp(0.0, 1.0),
        boxes[i * 4].clamp(0.0, 1.0),
        boxes[i * 4 + 3].clamp(0.0, 1.0),
        boxes[i * 4 + 2].clamp(0.0, 1.0),
      );
      if (box.width < 0.01 || box.height < 0.01) continue;
      out.add(RawDetection(classForLabel(label), box, score));
    }
    return out;
  }

  Future<void> close() async {
    await _isolate.close();
    _interpreter.close();
  }
}
