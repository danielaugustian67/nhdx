import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/widgets/app_tab_bar.dart';
import 'package:nihondx/app.dart';
import 'package:nihondx/core/database/providers.dart';

void main() {
  testWidgets('opens on Hari ini with five tabs and switches to Kamus', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('id')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        // Keep the dictionary "installing" so the test does not touch disk.
        overrides: [dictionaryProvider.overrideWith((ref) => Completer<Never>().future)],
        child: const NihondxApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final tab in ['Hari ini', 'Kamus', 'Koleksi', 'Saya']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.descendant(of: find.byType(AppTabBar), matching: find.text('Kana')), findsOneWidget);

    await tester.tap(find.text('Kamus'));
    await tester.pumpAndSettle();
    expect(find.text('Cari kata, kanji, atau arti'), findsOneWidget);
    expect(find.text('Menyiapkan kamus. Ini hanya terjadi sekali.'), findsOneWidget);
  });

  testWidgets('quick search opens Kamus with the field focused, by button or pull down', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('id')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dictionaryProvider.overrideWith((ref) => Completer<Never>().future)],
        child: const NihondxApp(),
      ),
    );
    await tester.pumpAndSettle();
    final nav = find.byType(AppTabBar);
    int selectedTab() => tester.widget<AppTabBar>(nav).selectedIndex;
    bool fieldFocused() => tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

    await tester.tap(find.descendant(of: nav, matching: find.text('Kana')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cari di kamus'));
    await tester.pumpAndSettle();
    expect(selectedTab(), 2);
    expect(fieldFocused(), isTrue);

    await tester.tap(find.descendant(of: nav, matching: find.text('Koleksi')));
    await tester.pumpAndSettle();
    expect(selectedTab(), 3);

    // A short pull does nothing; a long one at the top opens search.
    await tester.tap(find.descendant(of: nav, matching: find.text('Kana')));
    await tester.pumpAndSettle();
    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(selectedTab(), 1);
    await tester.drag(list, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(selectedTab(), 2);
    expect(fieldFocused(), isTrue);
  });
}
