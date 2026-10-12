import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/search/search_service.dart';
import 'package:nihondx/features/search/widgets/word_row.dart';

import '../helpers/fonts.dart';

/// Golden tests for the search result row (ui-design §4.5, §12): light/dark
/// and text scale 100%/200%, rendered with the real bundled fonts.
/// Update with: flutter test --update-goldens test/widget

const _hits = [
  SearchHit(
    wordId: 1358280,
    kanji: '食べる',
    kana: 'たべる',
    romaji: 'taberu',
    gloss: 'to eat',
    jlptLevel: 5,
    isCommon: true,
    isExact: true,
  ),
  SearchHit(
    wordId: 1358300,
    kanji: '食べ物',
    kana: 'たべもの',
    romaji: 'tabemono',
    gloss: 'food; provisions; something to eat; long gloss that should wrap onto a second line and then be cut',
    jlptLevel: 4,
    isCommon: true,
    isExact: false,
  ),
  SearchHit(
    wordId: 1049180,
    kanji: null,
    kana: 'コーヒー',
    romaji: 'koohii',
    gloss: 'coffee',
    jlptLevel: null,
    isCommon: true,
    isExact: false,
  ),
];

Widget _list(ThemeData theme, double textScale) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  home: MediaQuery(
    data: MediaQueryData(size: const Size(390, 520), textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: Column(
        children: [
          for (final hit in _hits) ...[WordRow(hit: hit), const Divider()],
        ],
      ),
    ),
  ),
);

void main() {
  setUpAll(loadAppFonts);

  for (final (name, theme) in [('light', AppTheme.light()), ('dark', AppTheme.dark())]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('WordRow $name ${(scale * 100).round()}%', (tester) async {
        tester.view.physicalSize = Size(390, scale == 1.0 ? 420 : 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_list(theme, scale));
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/word_row_${name}_${(scale * 100).round()}.png'),
        );
        expect(tester.takeException(), isNull, reason: 'no overflow at ${scale}x');
      });
    }
  }
}
