import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/kana/games/game_result_view.dart';
import 'package:nihondx/l10n/app_localizations.dart';

/// The result screen decides whether a learning-path lesson counts as done:
/// "Selesai" pops `true` only at or above the pass mark.
void main() {
  Future<Object?> finish(WidgetTester tester, {required double accuracy, double? passMark, String? tap}) async {
    Object? result = 'not popped';
    var replayed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('id'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: GameResultView(
                      xp: 30,
                      accuracy: accuracy,
                      passMark: passMark,
                      onPlayAgain: () => replayed = true,
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    if (tap != null) {
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
    }
    return replayed ? 'replayed' : result;
  }

  testWidgets('exactly the pass mark passes', (tester) async {
    expect(await finish(tester, accuracy: 0.8, passMark: 0.8, tap: 'Selesai'), isTrue);
  });

  testWidgets('below the pass mark offers a retry instead of Selesai', (tester) async {
    final r = await finish(tester, accuracy: 0.7, passMark: 0.8);
    expect(r, 'not popped');
    expect(find.text('Hampir!'), findsOneWidget);
    expect(find.textContaining('80%'), findsOneWidget);
    expect(find.text('Selesai'), findsNothing);
  });

  testWidgets('retry restarts the game', (tester) async {
    expect(await finish(tester, accuracy: 0.5, passMark: 0.8, tap: 'Coba lagi'), 'replayed');
  });

  testWidgets('quitting below the pass mark does not complete the node', (tester) async {
    expect(await finish(tester, accuracy: 0.5, passMark: 0.8, tap: 'Keluar'), isNull);
  });

  testWidgets('free play has no pass mark', (tester) async {
    expect(await finish(tester, accuracy: 0.1, tap: 'Selesai'), isTrue);
  });
}
