import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/korean_dict_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/conjugation/ko_conjugation.dart';
import 'package:nihondx/features/conjugation/ko_conjugation_drill_screen.dart';
import 'package:nihondx/features/conjugation/ko_conjugation_practice.dart';
import 'package:nihondx/features/grammar/grammar_practice.dart';
import 'package:nihondx/features/grammar/grammar_providers.dart';
import 'package:nihondx/features/learn/study_language.dart';
import 'package:nihondx/features/search/search_screen.dart';
import 'package:nihondx/features/srs/review_screen.dart';
import 'package:nihondx/features/word/korean_word_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';
import 'package:nihondx/l10n/app_localizations_id.dart';

/// Korean grammar points and the Korean conjugation drill: content, the
/// screens, their review cards and the word page's table. Runs against the
/// pipeline output.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const koreanPath = 'data_pipeline/output/korean.db';
  final skip = File(contentPath).existsSync() && File(koreanPath).existsSync()
      ? false
      : 'content.db or korean.db not built';
  final l10n = AppLocalizationsId();

  late List<GrammarPoint> points;
  late List<KoWord> words;
  setUpAll(() {
    if (skip != false) return;
    final content = ContentDb.open(contentPath);
    points = content.koreanGrammar();
    words = content.koreanWords();
    content.close();
  });

  test('content.db has the Korean points, with romanized examples and a gap in every quiz', () {
    expect(points, hasLength(greaterThanOrEqualTo(20)));
    expect(points.first.id, 'ko1-eun-neun');
    expect(points.map((p) => p.id).toSet(), hasLength(points.length));
    for (final p in points) {
      expect(p.korean, isTrue);
      expect(p.cardType, 'ko_grammar');
      expect(p.id, startsWith('ko1-'));
      expect(p.meaning.id, isNotEmpty, reason: p.id);
      expect(p.explanation.en, isNotEmpty, reason: p.id);
      for (final q in p.quiz) {
        expect(GrammarQuiz.gap.allMatches(q.question), hasLength(1), reason: p.id);
        expect(q.options.toSet(), hasLength(q.options.length), reason: p.id);
      }
      for (final e in p.examples) {
        expect(e.kana, e.japanese, reason: p.id);
        expect(e.romanization, isNotEmpty, reason: p.id);
        expect(e.chunks.join(' '), e.japanese.replaceAll(RegExp(r'[.?!]$'), ''), reason: p.id);
      }
    }
    // Korean exercises are built and checked like the Japanese ones.
    for (final e in buildGrammarExercises(points, count: 100, random: Random(3))) {
      if (e case BuildExercise(:final example)) expect(e.accepts(example.chunks), isTrue);
    }
  }, skip: skip);

  test('every course verb and adjective but 이다 and 아니다 can be drilled', () {
    final drill = koConjWords(words);
    final courseVerbs = words.where((w) => w.topic == 'verbs' || w.topic == 'adjectives').map((w) => w.hangul);
    expect(drill.map((w) => w.word.hangul).toSet(), courseVerbs.toSet().difference({'이다', '아니다'}));
    String polite(String w) => drill.firstWhere((d) => d.word.hangul == w).conj.conjugate(KoForm.polite);
    expect(polite('더럽다'), '더러워요');
    expect(polite('차갑다'), '차가워요');
    expect(polite('놀다'), '놀아요');
    expect(polite('일어나다'), '일어나요');
    expect(polite('맛없다'), '맛없어요');

    final questions = buildKoConjQuestions(drill, KoForm.values.toSet(), count: 10, random: Random(5));
    expect(questions, hasLength(10));
    expect(questions.map((q) => q.word.word.id).toSet(), hasLength(10));
    for (final q in questions) {
      expect(q.options, hasLength(4));
      expect(q.options.toSet(), hasLength(4));
      expect(q.right, q.word.conj.conjugate(q.form));
      expect(q.cardItemId, '${q.word.word.id}:${q.form.name}');
    }
  }, skip: skip);

  group('screens', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        for (var j = 0; j < 3; j++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
    }

    Future<UserDb> pump(WidgetTester tester, Widget home, {Future<void> Function(UserDb db)? setup}) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final db = UserDb.memory();
      await tester.runAsync(() async {
        await db.setSetting(StudyLanguage.settingKey, StudyLanguage.ko.name);
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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
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

    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await settle(tester);
    }

    bool shown(String text) => find.text(text).evaluate().isNotEmpty;
    final progress = find.textContaining(RegExp(r'^\d+ / \d+$'));

    testWidgets('the Kamus tab opens Korean grammar; passing a point marks it done and adds a ko_grammar card', (
      tester,
    ) async {
      final point = points.first;
      final db = await pump(tester, const SearchScreen());
      await tap(tester, find.text('Tata bahasa'));
      expect(find.text('TOPIK I'), findsOneWidget);
      expect(find.text(point.pattern), findsOneWidget);
      await tap(tester, find.text(point.pattern));
      expect(find.text(point.examples.first.japanese), findsOneWidget);
      expect(find.text(point.examples.first.romanization!), findsOneWidget);

      await tap(tester, find.text('Latihan'));
      while (progress.evaluate().isNotEmpty) {
        if (shown('Isi bagian yang kosong')) {
          final q = point.quiz.firstWhere((q) => shown(q.translation.id));
          await tap(tester, find.text(q.options[q.answer]).last);
        } else {
          final e = point.examples.firstWhere((e) => shown(e.translation.id));
          for (final chunk in e.chunks) {
            await tap(tester, find.text(chunk).last);
          }
          await tap(tester, find.text('Periksa'));
        }
        expect(find.text('Benar!'), findsOneWidget);
        await tap(tester, find.text('Lanjut'));
      }
      expect(find.text('완'), findsOneWidget);
      await tap(tester, find.text('Selesai'));
      await tap(tester, find.text('Tambah ke review'));
      expect(await tester.runAsync(() => db.watchCardItems('ko_grammar').first), {point.id});
      expect(await tester.runAsync(() => db.watchCardItems('grammar').first), isEmpty);
      expect(await tester.runAsync(() => db.doneLessons()), contains(grammarDoneKey(point.id)));
      await unmount(tester);
    }, skip: skip != false);

    testWidgets('the Korean drill asks course words; mistakes become ko_conjugation cards', (tester) async {
      final drill = koConjWords(words);
      final db = await pump(tester, const KoConjugationDrillScreen());
      expect(find.text(l10n.koConjForm('polite')), findsOneWidget);
      await tap(tester, find.text('Mulai (10 soal)'));
      final asked = <KoConjQuestion>[];
      while (progress.evaluate().isNotEmpty) {
        final word = drill.firstWhere((w) => shown(w.word.hangul));
        final form = KoForm.values.firstWhere((f) => shown(l10n.koConjForm(f.name)));
        final right = word.conj.conjugate(form);
        // The first answer right, the rest wrong.
        final wrong = word.conj.distractors(form).firstWhere(shown);
        await tap(tester, find.text(asked.isEmpty ? right : wrong).last);
        asked.add(KoConjQuestion(word: word, form: form, options: [right], answer: 0));
        expect(find.text(asked.length == 1 ? 'Benar!' : 'Jawabannya: $right'), findsOneWidget);
        await tap(tester, find.text('Lanjut'));
      }
      expect(asked, hasLength(10));
      expect(find.text('연'), findsOneWidget);
      final add = find.text('Masukkan yang salah ke review');
      await tester.scrollUntilVisible(add, 300, scrollable: find.byType(Scrollable).first);
      await tap(tester, add);
      final cards = await tester.runAsync(() => db.watchCardItems('ko_conjugation').first);
      expect(cards, {for (final q in asked.skip(1)) q.cardItemId});
      await unmount(tester);
    }, skip: skip != false);

    testWidgets('Korean grammar and conjugation cards review in the Korean queue', (tester) async {
      final point = points.first;
      final eat = koConjWords(words).firstWhere((w) => w.word.hangul == '먹다');
      await pump(
        tester,
        const ReviewScreen(),
        setup: (db) async {
          await db.addCard('ko_grammar', point.id, label: point.pattern);
          await db.addCard('ko_conjugation', koConjItemId(eat.word.id, KoForm.past), label: '먹다 → 먹었어요');
        },
      );
      for (var i = 0; i < 2; i++) {
        if (shown(point.pattern)) {
          await tap(tester, find.text('Tampilkan jawaban'));
          expect(find.text(point.meaning.id), findsOneWidget);
          expect(find.text(point.examples.first.japanese), findsOneWidget);
          expect(find.text('N1'), findsNothing);
        } else {
          expect(find.text('먹다'), findsOneWidget);
          expect(find.text(l10n.koConjForm('past')), findsWidgets);
          await tap(tester, find.text('Tampilkan jawaban'));
          expect(find.text('먹었어요'), findsOneWidget);
        }
        await tap(tester, find.text('Baik'));
      }
      await unmount(tester);
    }, skip: skip != false);

    testWidgets('a Korean verb page shows its conjugation table', (tester) async {
      final eat = words.firstWhere((w) => w.hangul == '먹다');
      await pump(tester, KoreanWordScreen(wordId: eat.id));
      await tester.scrollUntilVisible(find.text('먹었어요'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('먹어요'), findsOneWidget);
      expect(find.text('드세요'), findsOneWidget);
      expect(find.text(l10n.koConjForm('formal')), findsOneWidget);
      await unmount(tester);
    }, skip: skip != false);
  });
}
