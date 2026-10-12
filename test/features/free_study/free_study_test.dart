import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/free_study/free_study_providers.dart';
import 'package:nihondx/features/free_study/free_study_screen.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/srs/review_screen.dart';
import 'package:nihondx/features/today/today_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

/// Hafalan Bebas: pick groups, mark cards Hafal/Belum, undo, repeat the
/// Belum cards and send them to the daily review. Kanji cards review too.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const dictPath = 'data_pipeline/output/dictionary.db';
  final skip = File(contentPath).existsSync() ? false : 'content.db not built';
  final dictSkip = skip != false || !File(dictPath).existsSync() ? 'content.db or dictionary.db not built' : false;

  late UserDb db;

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = UserDb.memory();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
          userDbProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
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
  }

  /// Drift streams close on the next tick after the tree goes.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  Future<Set<String>> savedMarks(WidgetTester tester, String key) async =>
      (await tester.runAsync(() async {
        final json = await db.setting(key);
        return json == null ? <String>{} : (jsonDecode(json) as List).cast<String>().toSet();
      }))!;

  test('hiragana groups follow the path lessons', () {
    const units = [
      PathUnit(
        id: 'u1',
        number: 1,
        script: 'hiragana',
        rows: ['a'],
        nodes: [
          PathNode(id: 'n1', type: NodeType.intro, items: [], reviewPool: []),
          PathNode(id: 'n2', type: NodeType.review, items: [], reviewPool: []),
        ],
      ),
      PathUnit(
        id: 'u2',
        number: 2,
        script: 'katakana',
        rows: ['a'],
        nodes: [PathNode(id: 'n3', type: NodeType.intro, items: [], reviewPool: [])],
      ),
    ];
    expect(studyGroups(units, StudyKind.hiragana).map((g) => g.id), ['n1']);
    expect(studyGroups(units, StudyKind.katakana).map((g) => (g.id, g.unit)), [('n3', 1)]);
  });

  testWidgets('marks cards, undoes, repeats the Belum ones and adds them to review', (tester) async {
    await pump(tester, const FreeStudyScreen());
    expect(find.text('Pilih grup dulu'), findsOneWidget);

    await tapAndSettle(tester, find.bySemanticsLabel(RegExp(r'^あいうえお, 0 dari 5 hafal')));
    await tapAndSettle(tester, find.text('Mulai (5 kartu)'));
    expect(find.text('1 / 5'), findsOneWidget);

    // Flip, then Hafal ×3, Belum ×2, with one Belum taken back on the way.
    await tapAndSettle(tester, find.text('Ketuk untuk balik'));
    await tapAndSettle(tester, find.text('Hafal'));
    await tapAndSettle(tester, find.text('Hafal'));
    await tapAndSettle(tester, find.text('Belum'));
    expect(find.text('4 / 5'), findsOneWidget);
    await tapAndSettle(tester, find.byTooltip('Urungkan'));
    expect(find.text('3 / 5'), findsOneWidget);
    await tapAndSettle(tester, find.text('Hafal'));
    await tapAndSettle(tester, find.text('Belum'));
    await tapAndSettle(tester, find.text('Belum'));

    expect(find.text('Hafal 3 · Belum 2'), findsOneWidget);
    expect(await savedMarks(tester, StudyMarksNotifier.knownKey), hasLength(3));
    expect(await savedMarks(tester, StudyMarksNotifier.notYetKey), hasLength(2));

    await tapAndSettle(tester, find.text('Masukkan ke review harian'));
    expect(find.text('Sudah masuk review'), findsOneWidget);
    final cards = await tester.runAsync(() => db.watchCardItems('kana').first);
    expect(cards, hasLength(2));

    await tapAndSettle(tester, find.text('Ulangi yang belum (2)'));
    expect(find.text('1 / 2'), findsOneWidget);

    // Back on the picker: the tile counts the marks, the shortcuts appear.
    await tapAndSettle(tester, find.byTooltip('Keluar'));
    expect(find.bySemanticsLabel(RegExp(r'^あいうえお, 3 dari 5 hafal')), findsOneWidget);
    expect(find.text('Yang belum hafal (2)'), findsOneWidget);
    expect(find.textContaining('Lanjutkan: あいうえお'), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('the Today screen opens Hafalan Bebas', (tester) async {
    await pump(tester, const TodayScreen());
    await tapAndSettle(tester, find.text('Hafalan Bebas'));
    expect(find.text('Pilih grup dulu'), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('swiping right marks Hafal, left marks Belum', (tester) async {
    await pump(tester, const FreeStudyScreen());
    await tapAndSettle(tester, find.bySemanticsLabel(RegExp(r'^あいうえお')));
    await tapAndSettle(tester, find.text('Mulai (5 kartu)'));

    final card = find.text('Ketuk untuk balik');
    await tester.fling(card, const Offset(300, 0), 1000);
    await settle(tester);
    expect(find.text('2 / 5'), findsOneWidget);
    await tester.fling(card, const Offset(-300, 0), 1000);
    await settle(tester);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(await savedMarks(tester, StudyMarksNotifier.knownKey), hasLength(1));
    expect(await savedMarks(tester, StudyMarksNotifier.notYetKey), hasLength(1));
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('kanji groups open and the meaning-first option asks for the kanji', (tester) async {
    await pump(tester, const FreeStudyScreen());
    await tapAndSettle(tester, find.text('Arti dulu'));
    await tapAndSettle(tester, find.text('Kanji'));
    await tapAndSettle(tester, find.bySemanticsLabel(RegExp(r'dari \d+ hafal$')).first);
    await tapAndSettle(tester, find.textContaining(RegExp(r'^Mulai \(')));
    expect(find.text('Kanji apa yang artinya ini?'), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('a kanji card shows in the daily review with its readings', (tester) async {
    final content = ContentDb.open(contentPath);
    addTearDown(content.close);
    final kanji = content.kanji().firstWhere((k) => k.literal == '日');
    db = UserDb.memory();
    addTearDown(db.close);
    await tester.runAsync(() => db.addCard('kanji', '日', label: '日'));
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
          home: const ReviewScreen(),
        ),
      ),
    );
    // The queue loads kana and kanji from content.db first.
    for (var i = 0; i < 5 && find.text('日').evaluate().isEmpty; i++) {
      await settle(tester);
    }
    expect(find.text('日'), findsOneWidget);
    await tapAndSettle(tester, find.text('Tampilkan jawaban'));
    expect(find.text(kanji.meanings.take(3).join(', ')), findsOneWidget);
    expect(find.textContaining(kanji.onyomi.first), findsOneWidget);
    await unmount(tester);
  }, skip: dictSkip != false);
}
