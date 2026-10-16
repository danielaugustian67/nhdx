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
}
