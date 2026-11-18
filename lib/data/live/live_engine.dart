// Picks the real camera + TFLite engine where dart:ffi exists (Android, iOS,
// desktop) and a stub on the web, so the web build never imports FFI code.
export 'live_engine_result.dart';
export 'live_engine_stub.dart' if (dart.library.ffi) 'live_engine_io.dart';
