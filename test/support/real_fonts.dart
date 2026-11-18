import 'dart:io';

import 'package:flutter/services.dart';

/// flutter_test draws every glyph as a full square (~1.8× wider than Roboto)
/// and icons as boxes. Load the real fonts shipped with the Flutter SDK so
/// layout measurements and screenshots match a real phone.
Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var any = false;
    for (final f in files) {
      final file = File('$dir/$f');
      if (file.existsSync()) {
        loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        any = true;
      }
    }
    if (any) await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);

  final mono = File(r'C:\Windows\Fonts\consola.ttf');
  if (mono.existsSync()) {
    await (FontLoader('monospace')
          ..addFont(Future.value(ByteData.sublistView(mono.readAsBytesSync()))))
        .load();
  }
}
