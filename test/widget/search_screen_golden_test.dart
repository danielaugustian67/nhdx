import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/search/search_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

import '../helpers/fonts.dart';

/// Search field + mode chips (ui-design §4.5, §5.3). The chips mix kana with
/// Latin text, which must render with the bundled Japanese font.
void main() {
  setUpAll(loadAppFonts);

  for (final (name, theme) in [('light', AppTheme.light()), ('dark', AppTheme.dark())]) {
    testWidgets('SearchScreen header $name', (tester) async {
      tester.view.physicalSize = const Size(390, 260);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dictionaryProvider.overrideWith((ref) => Completer<Never>().future)],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            locale: const Locale('id'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'taberu');
      await tester.pump();

      await expectLater(find.byType(SearchScreen), matchesGoldenFile('goldens/search_header_$name.png'));
    });
  }
}
