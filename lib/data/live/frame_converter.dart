import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Converts a camera frame into a square, upright RGB888 buffer for the model.
///
/// Rotation, resize (nearest neighbour) and colour conversion happen in a
/// single pass over the *output* pixels, so cost is O(size²) — about 90k
/// pixels for a 300×300 model — regardless of camera resolution.
///
/// Supports Android YUV_420_888 (3 planes, any row/pixel stride), NV21
/// (1 plane) and iOS BGRA8888.
Uint8List convertCameraImage(CameraImage image, {required int rotation, required int size}) {
  final out = Uint8List(size * size * 3);
  final srcW = image.width;
  final srcH = image.height;
  final rot = ((rotation % 360) + 360) % 360;
  final swap = rot == 90 || rot == 270;
  final upW = swap ? srcH : srcW;
  final upH = swap ? srcW : srcH;

  final group = image.format.group;
  final planes = image.planes;
  final p0 = planes[0].bytes;
  final row0 = planes[0].bytesPerRow;

  final isBgra = group == ImageFormatGroup.bgra8888;
  final isPlanarYuv = !isBgra && planes.length >= 3;
  final p1 = isPlanarYuv ? planes[1].bytes : null;
  final p2 = isPlanarYuv ? planes[2].bytes : null;
  final uvRow = isPlanarYuv ? planes[1].bytesPerRow : row0;
  final uvPix = isPlanarYuv ? (planes[1].bytesPerPixel ?? 1) : 2;
  final nv21Offset = row0 * srcH;

  var o = 0;
  for (var oy = 0; oy < size; oy++) {
    final uy = (oy * upH) ~/ size;
    for (var ox = 0; ox < size; ox++) {
      final ux = (ox * upW) ~/ size;

      // Map upright coordinate back into the sensor buffer.
      int sx, sy;
      switch (rot) {
        case 90:
          sx = uy;
          sy = srcH - 1 - ux;
        case 180:
          sx = srcW - 1 - ux;
          sy = srcH - 1 - uy;
        case 270:
          sx = srcW - 1 - uy;
          sy = ux;
        default:
          sx = ux;
          sy = uy;
      }

      int r, g, b;
      if (isBgra) {
        final i = sy * row0 + sx * 4;
        b = p0[i];
        g = p0[i + 1];
        r = p0[i + 2];
      } else {
        final y = p0[sy * row0 + sx];
        int u, v;
        if (isPlanarYuv) {
          final i = (sy >> 1) * uvRow + (sx >> 1) * uvPix;
          u = p1![i] - 128;
          v = p2![i] - 128;
        } else {
          // NV21: interleaved V/U after the Y plane.
          final i = nv21Offset + (sy >> 1) * row0 + (sx & ~1);
          v = p0[i] - 128;
          u = p0[i + 1] - 128;
        }
        r = y + ((1436 * v) >> 10);
        g = y - ((352 * u + 731 * v) >> 10);
        b = y + ((1815 * u) >> 10);
        r = r < 0 ? 0 : (r > 255 ? 255 : r);
        g = g < 0 ? 0 : (g > 255 ? 255 : g);
        b = b < 0 ? 0 : (b > 255 ? 255 : b);
      }
      out[o++] = r;
      out[o++] = g;
      out[o++] = b;
    }
  }
  return out;
}
