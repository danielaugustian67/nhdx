import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the OFL licenses of the bundled fonts to Flutter's license page
/// (PRD F9 "Tentang & Atribusi"). Dataset attributions (JMdict, KANJIDIC2,
/// KanjiVG, JLPT lists) live in the databases' meta tables.
void registerFontLicenses() {
  const fonts = {
    'PlusJakartaSans': 'Plus Jakarta Sans',
    'ZenKakuGothicNew': 'Zen Kaku Gothic New',
    'ShipporiMincho': 'Shippori Mincho',
    'KleeOne': 'Klee One',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: file, value: name) in fonts.entries) {
      final text = await rootBundle.loadString('assets/fonts/licenses/$file-OFL.txt');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
