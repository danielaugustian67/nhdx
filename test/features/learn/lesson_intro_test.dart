import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/learn/lesson.dart';
import 'package:nihondx/features/learn/lesson_intro_screen.dart';
import 'package:nihondx/features/learn/lesson_screen.dart';
import 'package:nihondx/features/learn/vocab_path.dart';
import 'package:nihondx/l10n/app_localizations.dart';

void main() {
  const word1 = DictWord(id: 10, kana: 'あか', kanji: '赤', romaji: 'aka', jlpt: 5, gloss: 'merah');
  const word2 = DictWord(id: 11, kana: 'あお', kanji: '青', romaji: 'ao', jlpt: 5, gloss: 'biru');

  testWidgets('a finished word lesson can go straight to the quiz', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final items = [VocabWord(word1), VocabWord(word2)];
    final lessonBuilder = VocabLessonBuilder(
      focus: items,
      pool: items,
    );

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
          home: LessonIntroScreen(items: items, lesson: lessonBuilder, replay: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Langsung ke quiz'), findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing);

    await tester.tap(find.text('Langsung ke quiz'));
    await tester.pumpAndSettle();

    // Now LessonScreen should be displayed directly
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('a word is practised by reading, then picking its meaning', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const kanaOnly = DictWord(id: 12, kana: 'これ', romaji: 'kore', jlpt: 5, gloss: 'ini');
    final items = [VocabWord(word1), VocabWord(kanaOnly)];
    final lessonBuilder = VocabLessonBuilder(focus: items, pool: [...items, VocabWord(word2)]);

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
          home: LessonIntroScreen(items: items, lesson: lessonBuilder),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1/2 · Kenali'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('1/2 · Baca'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'aka');
    await tester.pump();
    await tester.tap(find.text('Periksa'));
    await tester.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('1/2 · Arti'), findsOneWidget);
    await tester.tap(find.text('merah'));
    await tester.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);

    // A kana-only word has nothing to read: card, then meaning.
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('2/2 · Kenali'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('2/2 · Arti'), findsOneWidget);
    expect(find.text('Mulai quiz'), findsOneWidget);
  });
}
