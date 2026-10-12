import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/grammar/grammar_practice.dart';
import 'package:nihondx/features/grammar/grammar_practice_screen.dart';
import 'package:nihondx/features/grammar/grammar_providers.dart';
import 'package:nihondx/features/grammar/grammar_screen.dart';
import 'package:nihondx/features/srs/review_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

/// Grammar points (F13): content, exercises, the practice screen and the
/// review card.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const dictPath = 'data_pipeline/output/dictionary.db';
  final skip = File(contentPath).existsSync() ? false : 'content.db not built';
  final dictSkip = skip != false || !File(dictPath).existsSync() ? 'content.db or dictionary.db not built' : false;

  GrammarPoint point(String id, {int quiz = 2, int examples = 1}) => GrammarPoint(
    id: id,
    jlpt: 5,
    orderNo: 1,
    pattern: '〜$id',
    formation: '',
    meaning: const Localized('arti', 'meaning'),
    explanation: const Localized('', ''),
    examples: [
      for (var i = 0; i < examples; i++)
        GrammarExample(
          japanese: 'わたしは学生です。',
          kana: 'わたしはがくせいです。',
          translation: const Localized('Saya pelajar.', 'I am a student.'),
          chunks: const ['わたしは', '学生', 'です'],
        ),
    ],
    quiz: [
      for (var i = 0; i < quiz; i++)
        GrammarQuiz(
          question: 'これ＿＿本です。',
          options: const ['は', 'を', 'に'],
          answer: 0,
          translation: const Localized('Ini buku.', 'This is a book.'),
        ),
    ],
  );

  test('exercises cover every point, keep the right answer and shuffle the tiles', () {
    final points = [point('a'), point('b'), point('c', quiz: 5)];
    final exercises = buildGrammarExercises(points, count: 6, random: Random(1));
    expect(exercises, hasLength(6));
    // Round-robin: each point gets two before any gets a third.
    for (final p in points) {
      expect(exercises.where((e) => e.point == p), hasLength(2));
    }
    for (final e in exercises) {
      switch (e) {
        case GapExercise():
          expect(e.options[e.answer], 'は');
          expect(e.sentence, 'これは本です。');
        case BuildExercise():
          expect(e.tiles.toSet(), {'わたしは', '学生', 'です'});
          expect(e.tiles.join(), isNot('わたしは学生です'));
          expect(e.accepts(['わたしは', '学生', 'です']), isTrue);
          expect(e.accepts(['学生', 'わたしは', 'です']), isFalse);
      }
    }
    expect(buildGrammarExercises([point('a')], random: Random(2)), hasLength(3));
  });

  test('content.db has the N5 points, each with a gap quiz and a sentence to build', () {
    final content = ContentDb.open(contentPath);
    addTearDown(content.close);
    final points = content.grammar();
    expect(points.length, greaterThanOrEqualTo(30));
    expect(points.first.id, 'n5-wa-desu');
    expect(points.map((p) => p.id).toSet(), hasLength(points.length));
    for (final p in points) {
      expect(p.meaning.id, isNotEmpty, reason: p.id);
      expect(p.meaning.en, isNotEmpty, reason: p.id);
      expect(p.quiz, isNotEmpty, reason: p.id);
      for (final q in p.quiz) {
        expect(GrammarQuiz.gap.allMatches(q.question), hasLength(1), reason: p.id);
        expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: p.id);
      }
      expect(p.examples.where((e) => e.chunks.isNotEmpty), isNotEmpty, reason: p.id);
      for (final e in p.examples.where((e) => e.chunks.isNotEmpty)) {
        expect(e.chunks.join(), e.japanese.replaceAll(RegExp(r'[。！？]$'), ''), reason: p.id);
      }
    }
  }, skip: skip);

  group('screens', () {
    late UserDb db;

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> pump(WidgetTester tester, Widget home, {bool dictionary = false}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
            if (dictionary) dictionaryProvider.overrideWith((ref) async => DictionaryDb.open(dictPath)),
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

    late List<GrammarPoint> points;

    setUp(() => db = UserDb.memory());
    tearDown(() => db.close());
    setUpAll(() {
      if (skip != false) return;
      final content = ContentDb.open(contentPath);
      points = content.grammar();
      content.close();
    });

    testWidgets('a point opens from the list, passing its practice marks it done', (tester) async {
      final point = points.first;
      await pump(tester, const GrammarScreen());
      expect(find.textContaining('0 dari'), findsOneWidget);
      await tap(tester, find.text(point.pattern));
      expect(find.text(point.meaning.id), findsOneWidget);
      expect(find.text(point.examples.first.japanese), findsOneWidget);

      await tap(tester, find.text('Latihan'));
      // Answer everything right: the gap by its translation, the tiles in order.
      while (find.textContaining(RegExp(r'^\d+ / \d+$')).evaluate().isNotEmpty) {
        if (find.text('Isi bagian yang kosong').evaluate().isNotEmpty) {
          final q = point.quiz.firstWhere((q) => find.text(q.translation.id).evaluate().isNotEmpty);
          await tap(tester, find.text(q.options[q.answer]).last);
        } else {
          final e = point.examples.firstWhere((e) => find.text(e.translation.id).evaluate().isNotEmpty);
          for (final chunk in e.chunks) {
            await tap(tester, find.text(chunk));
          }
          await tap(tester, find.text('Periksa'));
        }
        expect(find.text('Benar!'), findsOneWidget);
        await tap(tester, find.text('Lanjut'));
      }
      expect(find.textContaining(RegExp(r'^(\d+) dari \1 benar$')), findsOneWidget);
      expect(find.text('済'), findsOneWidget);

      await tap(tester, find.text('Selesai'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tap(tester, find.text('Tambah ke review'));
      expect(find.text('Ada di review'), findsOneWidget);
      expect(await tester.runAsync(() => db.watchCardItems('grammar').first), {point.id});
      final done = await tester.runAsync(() => db.doneLessons());
      expect(done, contains(grammarDoneKey(point.id)));
      await unmount(tester);
    }, skip: skip != false);

    testWidgets('a wrong pick shows the answer, mistakes go to the review', (tester) async {
      final point = points.first;
      await pump(tester, GrammarPracticeScreen(points: [point]));
      while (find.textContaining(RegExp(r'^\d+ / \d+$')).evaluate().isNotEmpty) {
        if (find.text('Isi bagian yang kosong').evaluate().isNotEmpty) {
          final q = point.quiz.firstWhere((q) => find.text(q.translation.id).evaluate().isNotEmpty);
          await tap(tester, find.text(q.options[(q.answer + 1) % q.options.length]).last);
        } else {
          final e = point.examples.firstWhere((e) => find.text(e.translation.id).evaluate().isNotEmpty);
          for (final chunk in e.chunks.reversed) {
            await tap(tester, find.text(chunk));
          }
          await tap(tester, find.text('Periksa'));
        }
        expect(find.textContaining('Jawabannya: '), findsOneWidget);
        await tap(tester, find.text('Lanjut'));
      }
      expect(find.text('習'), findsOneWidget);
      await tap(tester, find.text('Masukkan yang salah ke review'));
      expect(await tester.runAsync(() => db.watchCardItems('grammar').first), {point.id});
      expect(await tester.runAsync(() => db.doneLessons()), isNot(contains(grammarDoneKey(point.id))));
      await unmount(tester);
    }, skip: skip != false);

    testWidgets('a grammar card reviews with its meaning and an example', (tester) async {
      final point = points.first;
      await tester.runAsync(() => db.addCard('grammar', point.id, label: point.pattern));
      await pump(tester, const ReviewScreen(), dictionary: true);
      for (var i = 0; i < 5 && find.text(point.pattern).evaluate().isEmpty; i++) {
        await settle(tester);
      }
      expect(find.text(point.pattern), findsOneWidget);
      await tap(tester, find.text('Tampilkan jawaban'));
      expect(find.text(point.meaning.id), findsOneWidget);
      expect(find.text(point.examples.first.japanese), findsOneWidget);
      expect(find.text(point.examples.first.translation.id), findsOneWidget);
      await unmount(tester);
    }, skip: dictSkip != false);
  });
}
