import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/conjugation/conjugation.dart';
import 'package:nihondx/features/conjugation/conjugation_drill_screen.dart';
import 'package:nihondx/features/conjugation/conjugation_practice.dart';
import 'package:nihondx/features/kana/widgets/answer_option.dart';
import 'package:nihondx/features/search/search_screen.dart';
import 'package:nihondx/features/srs/review_screen.dart';
import 'package:nihondx/features/word/word_detail_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

/// Conjugation (F14) on screen: the table on a word page, the drill, the
/// review card and the way in from the Dictionary tab.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const dictPath = 'data_pipeline/output/dictionary.db';
  final skip = File(contentPath).existsSync() && File(dictPath).existsSync()
      ? false
      : 'content.db or dictionary.db not built';

  late UserDb db;
  late ConjWord taberu;

  setUpAll(() {
    if (skip != false) return;
    final dict = DictionaryDb.open(dictPath);
    final (:word, :pos) = dict.conjugableWords([5]).firstWhere((w) => w.word.kanji == '食べる');
    taberu = ConjWord(word, Conjugator.fromPos(pos, written: '食べる', kana: 'たべる')!);
    dict.close();
  });

  setUp(() => db = UserDb.memory());
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
          dictionaryProvider.overrideWith((ref) async => DictionaryDb.open(dictPath)),
          userDbProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('a verb page shows its forms and expands to all of them', (tester) async {
    await pump(tester, WordDetailScreen(wordId: taberu.word.id));
    await tester.scrollUntilVisible(find.text('食べます'), 300);
    expect(find.text('食べない'), findsOneWidget);
    expect(find.text('食べさせる'), findsNothing);
    await tap(tester, find.textContaining('Semua bentuk'));
    expect(find.text('食べさせる'), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('the drill of one word scores the round and sends mistakes to the review', (tester) async {
    await pump(tester, ConjugationDrillScreen.word(taberu));
    final right = {for (final f in taberu.conj.forms) taberu.conj.conjugate(f).written};
    var wrong = 0;
    while (find.textContaining(RegExp(r'^\d+ / 10$')).evaluate().isNotEmpty) {
      // A pick that is no form of 食べる at all when there is one, else the
      // first option.
      final options = [
        for (final e in find.descendant(of: find.byType(AnswerOption), matching: find.byType(Text)).evaluate())
          ?(e.widget as Text).data,
      ];
      final odd = options.where((o) => !right.contains(o)).firstOrNull;
      await tap(tester, find.text(odd ?? options.first).last);
      if (find.textContaining('Jawabannya').evaluate().isNotEmpty) wrong++;
      await tap(tester, find.text('Lanjut'));
    }
    expect(wrong, greaterThan(0));
    expect(find.text('${10 - wrong} dari 10 benar'), findsOneWidget);
    if (wrong > 0) {
      await tester.scrollUntilVisible(find.text('Masukkan yang salah ke review'), 200);
      await tap(tester, find.text('Masukkan yang salah ke review'));
      final cards = await tester.runAsync(() => db.watchCardItems('conjugation').first);
      expect(cards, hasLength(wrong));
      expect(cards!.every((id) => id.startsWith('${taberu.word.id}:')), isTrue);
    }
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('a conjugation card asks for the form and answers with it', (tester) async {
    await tester.runAsync(() => db.addCard('conjugation', '${taberu.word.id}:polite', label: '食べる → 食べます'));
    await pump(tester, const ReviewScreen());
    for (var i = 0; i < 5 && find.text('食べる').evaluate().isEmpty; i++) {
      await settle(tester);
    }
    expect(find.text('食べる'), findsOneWidget);
    expect(find.text('Sopan  〜ます'), findsOneWidget);
    await tap(tester, find.text('Tampilkan jawaban'));
    expect(find.text('食べます（たべます）'), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('the Dictionary tab opens grammar and the conjugation drill', (tester) async {
    await pump(tester, const SearchScreen());
    await tester.scrollUntilVisible(find.text('Latihan konjugasi'), 300, scrollable: find.byType(Scrollable).first);
    await tap(tester, find.text('Latihan konjugasi'));
    expect(find.text('Jenis kata'), findsOneWidget);
    await tap(tester, find.textContaining('Mulai'));
    expect(find.text('1 / 10'), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);
}
