import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/audio/speech.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/free_study/free_study_session_screen.dart';
import 'package:nihondx/features/learn/speech_text.dart';
import 'package:nihondx/l10n/app_localizations.dart';

class _FakeSpeech implements Speech {
  _FakeSpeech({this.available = true});
  final bool available;
  final said = <String>[];

  @override
  Future<bool> speak(String text) async {
    if (available) said.add(text);
    return available;
  }

  @override
  Future<void> stop() async {}
}

/// Reading aloud: what is said for each kind of item, autoplay on flip (and
/// its setting), the 🔊 button, and the hint when there is no Japanese voice.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  final skip = File(contentPath).existsSync() ? false : 'content.db not built';

  late ContentDb content;
  setUpAll(() {
    if (skip == false) content = ContentDb.open(contentPath);
  });
  tearDownAll(() {
    if (skip == false) content.close();
  });

  Kana kana(String literal) => content.kana().firstWhere((k) => k.literal == literal);

  test('kanji are said by their readings, without okurigana dots', () {
    final go = content.kanji().firstWhere((k) => k.literal == '五');
    final said = kanjiSpeech(go);
    expect(said, startsWith('ゴ'));
    expect(said, isNot(contains('.')));
    expect(speechText(kana('あ')), 'あ');
  }, skip: skip != false);

  Future<UserDb> pump(WidgetTester tester, Speech speech, {bool autoplay = true}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = UserDb.memory();
    addTearDown(db.close);
    if (!autoplay) await tester.runAsync(() => db.setSetting(speechAutoplayKey, 'off'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
          userDbProvider.overrideWith((ref) async => db),
          speechProvider.overrideWithValue(speech),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FreeStudySessionScreen(items: [kana('か'), kana('き')]),
        ),
      ),
    );
    await settle(tester);
    return db;
  }

  testWidgets('turning a card over reads it, and 🔊 reads it again', (tester) async {
    final speech = _FakeSpeech();
    await pump(tester, speech);
    expect(speech.said, isEmpty);

    await tester.tap(find.text('Ketuk untuk balik'));
    await settle(tester);
    expect(speech.said, ['か']);

    await tester.tap(find.byTooltip('Dengarkan'));
    await settle(tester);
    expect(speech.said, ['か', 'か']);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('with autoplay off only 🔊 reads', (tester) async {
    final speech = _FakeSpeech();
    await pump(tester, speech, autoplay: false);
    await tester.tap(find.text('Ketuk untuk balik'));
    await settle(tester);
    expect(speech.said, isEmpty);

    await tester.tap(find.byTooltip('Dengarkan'));
    await settle(tester);
    expect(speech.said, ['か']);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('without a Japanese voice 🔊 says how to install one', (tester) async {
    await pump(tester, _FakeSpeech(available: false));
    await tester.tap(find.text('Ketuk untuk balik'));
    await settle(tester);
    await tester.tap(find.byTooltip('Dengarkan'));
    await settle(tester);
    expect(find.textContaining('Suara bahasa Jepang belum ada'), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// Drift streams close on the next tick after the tree goes.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}
