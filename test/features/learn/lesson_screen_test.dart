import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/learn/lesson.dart';
import 'package:nihondx/features/learn/lesson_screen.dart';
import 'package:nihondx/features/learn/vocab_path.dart';
import 'package:nihondx/l10n/app_localizations.dart';

Kana _k(int id, String literal, String romaji) =>
    Kana(id: id, literal: literal, script: 'hiragana', romaji: romaji, rowGroup: 'a', kind: 'basic', orderNo: id);

void main() {
  final a = _k(1, 'あ', 'a'), ka = _k(2, 'か', 'ka'), i = _k(3, 'い', 'i'), e = _k(4, 'え', 'e');
  const aka = DictWord(id: 10, kana: 'あか', kanji: '赤', romaji: 'aka', jlpt: 5, gloss: 'red, crimson');
  const ie = DictWord(id: 11, kana: 'いえ', kanji: '家', romaji: 'ie', jlpt: 5, gloss: 'house, residence');

  Future<void> pump(WidgetTester tester, List<Exercise> exercises) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
          home: LessonScreen(exercises: () => exercises, passMark: 0.8),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('spell a dictionary word with tiles, then read one in romaji', (tester) async {
    await pump(tester, [
      BuildExercise(word: aka, prompt: 'aka', target: 'あか', script: 'hiragana', answer: [a, ka], tiles: [ka, i, a, e]),
      ReadExercise(word: ie, shown: 'いえ', items: [i, e]),
    ]);

    // Build: romaji + meaning shown, tap あ then か.
    expect(find.text('Susun dalam Hiragana'), findsOneWidget);
    expect(find.text('aka'), findsOneWidget);
    expect(find.text('red, crimson'), findsOneWidget);
    await tester.tap(find.text('あ'));
    await tester.pump();
    await tester.tap(find.text('か'));
    await tester.pump();
    await tester.tap(find.text('Periksa'));
    await tester.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);
    expect(find.textContaining('赤'), findsOneWidget); // dictionary entry in the feedback bar
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Read: いえ → type a wrong reading.
    expect(find.text('いえ'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ue');
    await tester.pump();
    await tester.tap(find.text('Periksa'));
    await tester.pumpAndSettle();
    expect(find.text('Jawabannya ie'), findsOneWidget);
    expect(find.textContaining('house'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // 1 of 2 = 50% < 80% → retry screen.
    expect(find.text('Hampir!'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('match words to meanings; one slip still counts as correct', (tester) async {
    const mizu = DictWord(id: 12, kana: 'みず', kanji: '水', romaji: 'mizu', jlpt: 5, gloss: 'water');
    await pump(tester, [
      MatchExercise(words: [VocabWord(aka), VocabWord(ie), VocabWord(mizu)], meaningOrder: [2, 0, 1]),
    ]);
    expect(find.text('Pasangkan kata dengan artinya'), findsOneWidget);
    await tester.tap(find.text('赤'));
    await tester.tap(find.text('water')); // wrong pair
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsWidgets);
    await tester.pump(const Duration(milliseconds: 600));
    for (final (word, meaning) in [('赤', 'red, crimson'), ('水', 'water'), ('家', 'house, residence')]) {
      await tester.tap(find.text(word));
      await tester.tap(find.text(meaning));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);
  });

  testWidgets('recall a word from its meaning in romaji', (tester) async {
    await pump(tester, [
      ReadExercise(word: ie, shown: ie.gloss, items: const [VocabWord(ie)], fromMeaning: true),
    ]);
    expect(find.text('Ketik kata Jepangnya dalam romaji'), findsOneWidget);
    expect(find.text('house, residence'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ie');
    await tester.pump();
    await tester.tap(find.text('Periksa'));
    await tester.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);
  });

  testWidgets('tapping a placed tile sends it back', (tester) async {
    await pump(tester, [
      BuildExercise(word: aka, prompt: 'aka', target: 'あか', script: 'hiragana', answer: [a, ka], tiles: [ka, i, a, e]),
    ]);
    await tester.tap(find.text('か'));
    await tester.pump();
    await tester.tap(find.text('か')); // now on the answer line
    await tester.pump();
    await tester.tap(find.text('あ'));
    await tester.pump();
    await tester.tap(find.text('か'));
    await tester.pump();
    await tester.tap(find.text('Periksa'));
    await tester.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);
  });
}
