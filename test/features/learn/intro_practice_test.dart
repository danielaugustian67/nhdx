import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/learn/lesson.dart';
import 'package:nihondx/features/learn/lesson_intro_screen.dart';
import 'package:nihondx/features/learn/lesson_screen.dart';
import 'package:nihondx/features/learn/vocab_path.dart';
import 'package:nihondx/l10n/app_localizations.dart';

Kana _hangul(int id, String literal, String romaji) =>
    Kana(id: id, literal: literal, script: 'hangul', romaji: romaji, rowGroup: 'c', kind: 'consonant', orderNo: id);

Kana _kana(int id, String literal, String romaji, {String script = 'hiragana'}) =>
    Kana(id: id, literal: literal, script: script, romaji: romaji, rowGroup: 'a', kind: 'basic', orderNo: id);

/// Every character has strokes.
bool _all(String _) => true;

void main() {
  group('reading a character', () {
    test('kana take any romanisation of the same kana', () {
      final shi = GlyphReadExercise(_kana(1, 'し', 'shi'), answers: const ['shi']);
      expect(shi.check('shi'), isTrue);
      expect(shi.check(' SI '), isTrue);
      expect(shi.check('chi'), isFalse);
      expect(shi.check(''), isFalse);
      final tsu = GlyphReadExercise(_kana(2, 'ツ', 'tsu', script: 'katakana'), answers: const ['tsu']);
      expect(tsu.check('tu'), isTrue);
      expect(tsu.check('su'), isFalse);
    });

    test('Hangul takes any listed variant, not kana conversions', () {
      final rieul = GlyphReadExercise(_hangul(1, 'ㄹ', 'r/l'), answers: const ['r', 'l'], korean: true);
      expect(rieul.check('r'), isTrue);
      expect(rieul.check('L'), isTrue);
      expect(rieul.check('r/l'), isFalse);
      final eo = GlyphReadExercise(_hangul(2, 'ㅓ', 'eo'), answers: const ['eo'], korean: true);
      expect(eo.check('eo'), isTrue);
      expect(eo.check('o'), isFalse);
    });

    test('a Hangul romanization with variants is split into answers', () {
      final rieul = _hangul(1, 'ㄹ', 'r/l');
      final b = KanaLessonBuilder(focus: [rieul], pool: [rieul]);
      final read = b.practice(rieul).single as GlyphReadExercise;
      expect(read.answers, ['r', 'l']);
      expect(read.korean, isTrue);
    });
  });

  test('a Korean word is practised by reading in romaja, then its meaning', () {
    const annyeong = DictWord(id: 90000001, kana: '안녕', romaji: 'annyeong', jlpt: 0, gloss: 'halo');
    const ne = DictWord(id: 90000002, kana: '네', romaji: 'ne', jlpt: 0, gloss: 'ya');
    final w = VocabWord(annyeong);
    final p = VocabLessonBuilder(focus: [w], pool: [w, VocabWord(ne)]).practice(w);
    expect(p, hasLength(2));
    final read = p.first as ReadExercise;
    expect(read.hint, isNull); // the meaning is asked next
    expect(read.check('annyeong'), isTrue);
    final meaning = p.last as ChoiceExercise;
    expect(meaning.kind, ChoiceKind.wordMeaning);
    expect(meaning.answer, 'halo');
  });

  test('a kanji word is read without its meaning, which is asked next', () {
    const imi = DictWord(id: 1, kanji: '意味', kana: 'いみ', romaji: 'imi', jlpt: 5, gloss: 'meaning');
    const natsu = DictWord(id: 2, kanji: '夏', kana: 'なつ', romaji: 'natsu', jlpt: 5, gloss: 'summer');
    final w = VocabWord(imi);
    final p = VocabLessonBuilder(focus: [w], pool: [w, VocabWord(natsu)]).practice(w);
    final read = p.first as ReadExercise;
    expect(read.shown, '意味');
    expect(read.hint, isNull);
    expect((p.last as ChoiceExercise).answer, 'meaning');
  });

  group('writing a word', () {
    const imi = DictWord(id: 1, kanji: '意味', kana: 'いみ', romaji: 'imi', jlpt: 5, gloss: 'meaning');
    const ichiban = DictWord(id: 2, kanji: '一番', kana: 'いちばん', romaji: 'ichiban', jlpt: 5, gloss: 'best');
    const bye = DictWord(id: 90000003, kana: '안녕히 가세요', romaji: 'annyeonghi gaseyo', jlpt: 0, gloss: 'bye');
    List<Exercise> practise(DictWord word, {bool Function(String)? canWrite = _all, Set<String> known = const {}}) {
      final w = VocabWord(word);
      return VocabLessonBuilder(
        focus: [w],
        pool: [w, VocabWord(imi), VocabWord(ichiban)],
        canWrite: canWrite,
        knownKanji: known,
      ).practice(w);
    }

    test('in kana first, then in kanji once all its kanji are known', () {
      final unknown = practise(imi).whereType<WriteExercise>().toList();
      expect(unknown.map((e) => e.literal), ['いみ']);
      expect(unknown.single.hint, 'imi');

      final partly = practise(ichiban, known: {'一'}).whereType<WriteExercise>();
      expect(partly.map((e) => e.literal), ['いちばん']);

      final known = practise(ichiban, known: {'一', '番'}).whereType<WriteExercise>().toList();
      expect(known.map((e) => e.literal), ['いちばん', '一番']);
      expect(known.last.hint, 'いちばん');
    });

    test('order: write, read, meaning', () {
      final p = practise(imi, known: {'意', '味'});
      expect(p.map((e) => e.runtimeType), [WriteExercise, WriteExercise, ReadExercise, ChoiceExercise]);
    });

    test('a Korean phrase is written in Hangul without its space', () {
      final write = practise(bye).whereType<WriteExercise>().single;
      expect(write.literal, '안녕히가세요');
    });

    test('nothing to write without strokes or when too long', () {
      expect(practise(imi, canWrite: null).whereType<WriteExercise>(), isEmpty);
      expect(practise(imi, canWrite: (c) => c != 'み').whereType<WriteExercise>(), isEmpty);
      const long = DictWord(id: 3, kana: 'ありがとうございます', romaji: 'arigatougozaimasu', jlpt: 5, gloss: 'thanks');
      expect(practise(long).whereType<WriteExercise>(), isEmpty);
    });
  });

  group('LessonIntroScreen', () {
    final g = _hangul(1, 'ㄱ', 'g'), n = _hangul(2, 'ㄴ', 'n'), d = _hangul(3, 'ㄷ', 'd'), m = _hangul(4, 'ㅁ', 'm');

    late UserDb db;

    /// Drift's stream timers must run out before the test ends.
    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(db.close);
    }

    Future<void> pump(WidgetTester tester, {String? progressKey, bool replay = false}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [userDbProvider.overrideWith((ref) async => db)],
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
            home: LessonIntroScreen(
              items: [g, n],
              // Hangul has no stroke data: card, then reading only.
              lesson: KanaLessonBuilder(focus: [g, n], pool: [g, n, d, m]),
              progressKey: progressKey,
              replay: replay,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('card, then reading practice, with back and next', (tester) async {
      db = UserDb.memory();
      await pump(tester);
      expect(find.text('1/2 · Kenali'), findsOneWidget);
      expect(find.text('Langsung ke quiz'), findsNothing);

      await tap(tester, 'Lanjut');
      expect(find.text('1/2 · Baca'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'g');
      await tester.pump();
      await tap(tester, 'Periksa');
      expect(find.text('Benar!'), findsOneWidget);

      // "Ulangi" starts the practice again, empty.
      await tap(tester, 'Ulangi');
      expect(find.text('Benar!'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

      await tap(tester, 'Kembali');
      expect(find.text('1/2 · Kenali'), findsOneWidget);
      await tap(tester, 'Lanjut');
      await tap(tester, 'Lanjut');
      expect(find.text('2/2 · Kenali'), findsOneWidget);
      await tap(tester, 'Lanjut');
      expect(find.text('2/2 · Baca'), findsOneWidget);

      // A wrong reading shows the answer; practice is not graded.
      await tester.enterText(find.byType(TextField), 'm');
      await tester.pump();
      await tap(tester, 'Periksa');
      expect(find.text('Jawabannya n'), findsOneWidget);

      await tap(tester, 'Mulai quiz');
      expect(find.byType(LessonScreen), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a finished node offers a shortcut to the quiz', (tester) async {
      db = UserDb.memory();
      await pump(tester, replay: true);
      expect(find.text('1/2 · Kenali'), findsOneWidget);
      await tap(tester, 'Langsung ke quiz');
      expect(find.byType(LessonScreen), findsOneWidget);
      await finish(tester);
    });

    testWidgets('practice continues where it was left', (tester) async {
      db = UserDb.memory();
      await pump(tester, progressKey: 'hangul-u1-intro-0');
      await tap(tester, 'Lanjut');
      await tap(tester, 'Lanjut');
      expect(find.text('2/2 · Kenali'), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(await tester.runAsync(() => db.setting(introProgressKey('hangul-u1-intro-0'))), '2');

      await tester.pumpWidget(const SizedBox());
      await pump(tester, progressKey: 'hangul-u1-intro-0');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('2/2 · Kenali'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a replay starts from the first card', (tester) async {
      db = UserDb.memory();
      await tester.runAsync(() => db.setSetting(introProgressKey('hangul-u1-intro-0'), '2'));
      await pump(tester, progressKey: 'hangul-u1-intro-0', replay: true);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('1/2 · Kenali'), findsOneWidget);
      await finish(tester);
    });
  });

  testWidgets('a failed quiz goes back to practice with the items answered wrong', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final a = _kana(1, 'あ', 'a');
    Set<Glyph>? weak;
    await tester.pumpWidget(
      ProviderScope(
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
          home: LessonScreen(
            passMark: 0.8,
            exercises: () => [
              ChoiceExercise(
                item: a,
                kind: ChoiceKind.kanaReading,
                prompt: 'あ',
                options: const ['a', 'i', 'u', 'e'],
                answerIndex: 0,
              ),
            ],
            onBackToPractice: (w) => weak = w,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('i'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    await tester.tap(find.text('Kembali ke latihan'));
    await tester.pumpAndSettle();
    expect(weak, {a});
  });

  testWidgets('a kanji card shows its readings in romaji', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const ichi = Kanji(
      id: 0x4E00,
      literal: '一',
      jlpt: 5,
      strokeCount: 1,
      meanings: ['one'],
      onyomi: ['イチ', 'イツ'],
      kunyomi: ['ひと', 'ひと.つ'],
      theme: 'numbers',
      orderNo: 1,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contentProvider.overrideWith((ref) => Completer<Never>().future)],
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
          home: LessonIntroScreen(
            items: const [ichi],
            lesson: KanjiLessonBuilder(focus: const [ichi], pool: const [ichi], hiragana: const []),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('イチ、イツ'), findsOneWidget);
    expect(find.text('ichi, itsu'), findsOneWidget);
    expect(find.text('ひと、ひと(つ)'), findsOneWidget);
    expect(find.text('hito, hito(tsu)'), findsOneWidget);
    expect(find.text('1/1 · Kenali'), findsOneWidget);
  });
}
