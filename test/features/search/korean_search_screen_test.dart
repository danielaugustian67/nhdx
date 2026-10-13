import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/korean_dict_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/collection/collection_screen.dart';
import 'package:nihondx/features/learn/study_language.dart';
import 'package:nihondx/features/search/search_screen.dart';
import 'package:nihondx/features/word/korean_word_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

/// The Kamus and Koleksi tabs while Korean is being learned: the Korean
/// dictionary instead of the Japanese one. Runs against the pipeline output.
void main() {
  const koreanPath = 'data_pipeline/output/korean.db';
  const contentPath = 'data_pipeline/output/content.db';
  final skip = !(File(koreanPath).existsSync() && File(contentPath).existsSync());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      for (var j = 0; j < 3; j++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
  }

  Future<UserDb> pumpTab(WidgetTester tester, Widget home, {Future<void> Function(UserDb db)? setup}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = UserDb.memory();
    await tester.runAsync(() async {
      await db.setSetting(StudyLanguage.settingKey, StudyLanguage.ko.name);
      await db.addHistory('食べる');
      await db.addHistory('사과');
      await setup?.call(db);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDbProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
          koreanDictProvider.overrideWith((ref) async => KoreanDictDb.open(koreanPath)),
          // The Japanese dictionary must not be needed.
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('id'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await settle(tester);
    return db;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('Kamus searches Korean by meaning and opens the Korean word page', (tester) async {
    final db = await pumpTab(tester, const SearchScreen());

    // No kana modes; Korean history and topics instead of JLPT levels.
    expect(find.text('Cari Hangul, romanisasi atau arti'), findsOneWidget);
    expect(find.text('Hiragana'), findsNothing);
    expect(find.text('사과'), findsOneWidget);
    expect(find.text('食べる'), findsNothing);
    expect(find.text('Telusuri per topik'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'apel');
    await settle(tester);
    expect(find.text('사과'), findsWidgets);
    expect(find.text('apel'), findsWidgets);

    await tester.tap(find.text('사과').first);
    await settle(tester);
    expect(find.byType(KoreanWordScreen), findsOneWidget);
    expect(find.text('sagwa'), findsOneWidget);
    expect(find.text('Arti dari Wiktionary (bahasa Inggris)'), findsOneWidget);
    // Parts of speech follow the app language.
    expect(find.textContaining('Kata benda'), findsWidgets);
    expect(find.textContaining('Noun'), findsNothing);

    await tester.tap(find.text('Tambah ke belajar'));
    await settle(tester);
    final cards = await tester.runAsync(() => db.watchCardItems('ko_word').first);
    expect(cards, isNotEmpty);
    expect(find.text('Sudah di belajar'), findsOneWidget);

    await unmount(tester);
  }, skip: skip);

  test('part of speech labels in Indonesian and English', () {
    final id = lookupAppLocalizations(const Locale('id'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(posLabel(id, 'noun'), 'Kata benda');
    expect(posLabel(en, 'noun'), 'Noun');
    expect(posLabel(id, 'verb'), 'Kata kerja');
    expect(posLabel(en, 'adj'), 'Adjective');
    expect(posLabel(id, 'unknown'), 'unknown');
    expect(posLabel(id, null), isNull);
  });

  testWidgets('Koleksi shows Korean bookmarks only, without JLPT chips', (tester) async {
    final dict = KoreanDictDb.open(koreanPath);
    final word = dict.wordOfTheDay('2026-10-13')!;
    dict.close();
    await pumpTab(
      tester,
      const CollectionScreen(),
      setup: (db) async {
        await db.setBookmark(word.id, on: true, label: word.kana);
        await db.setBookmark(1358280, on: true, label: '食べる');
      },
    );

    expect(find.text('N5'), findsNothing);
    expect(find.text('食べる'), findsNothing);
    expect(find.text(word.kana), findsOneWidget);

    await unmount(tester);
  }, skip: skip);
}
