import 'dart:io';

import 'package:flutter/services.dart';

/// flutter_test renders with a placeholder font unless app fonts are loaded
/// explicitly. Loads the bundled subset fonts for golden tests.
Future<void> loadAppFonts() async {
  const families = {
    'PlusJakartaSans': ['Regular', 'Medium', 'SemiBold'],
    'ZenKakuGothicNew': ['Regular'],
    'ShipporiMincho': ['Regular'],
    'KleeOne': ['Regular'],
  };
  for (final MapEntry(key: family, value: weights) in families.entries) {
    final loader = FontLoader(family);
    for (final w in weights) {
      final bytes = File('assets/fonts/$family-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  // Material icons ship with the Flutter SDK, not the app's assets.
  final sdk = Platform.environment['FLUTTER_ROOT'];
  final icons = File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (sdk != null && icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}
