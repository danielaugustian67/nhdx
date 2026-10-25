import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nihondx/l10n/app_localizations.dart';
import 'package:nihondx/main.dart' as app;

/// Walks the real app on a device: onboarding, every tab, and a dictionary
/// search. Any uncaught exception or overflow fails the run.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester, [int seconds = 3]) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('onboarding, every tab and a search', (tester) async {
    await app.main();
    await settle(tester, 5);

    AppLocalizations l10n() => AppLocalizations.of(tester.element(find.byType(Scaffold).first));

    if (find.text(l10n().languageQuestion).evaluate().isNotEmpty) {
      await tester.tap(find.text(l10n().languageJapaneseBody));
      await settle(tester);
      await tester.tap(find.text(l10n().next));
      await settle(tester);
      await tester.tap(find.text(l10n().levelFromZeroBody));
      await settle(tester);
      await tester.tap(find.text(l10n().next));
      await settle(tester);
      await tester.tap(find.text(l10n().next));
      await settle(tester);
      await tester.tap(find.text(l10n().skip));
      await settle(tester, 5);
    }

    for (final label in [
      l10n().tabKana,
      l10n().tabDictionary,
      l10n().tabCollection,
      l10n().tabMe,
      l10n().tabToday,
    ]) {
      await tester.tap(find.text(label).last);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'tab $label');
    }

    await tester.tap(find.text(l10n().tabDictionary).last);
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'taberu');
    await settle(tester, 15);
    expect(find.textContaining('食べる'), findsWidgets);
  });
}
