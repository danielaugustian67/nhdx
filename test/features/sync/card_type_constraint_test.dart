import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/features/learn/study_language.dart';

/// The cloud rejects a card whose type is not in the check constraint of
/// `user_srs_cards`, and a rejected batch stops the whole sync. Every card
/// type the app writes must be allowed by the newest migration.
void main() {
  test('the newest card_type constraint allows every card type', () {
    final migrations = Directory('supabase/migrations').listSync().whereType<File>().map((f) => f.path).toList()
      ..sort();
    final pattern = RegExp(r"card_type in \(([^)]*)\)");
    List<String>? allowed;
    for (final path in migrations) {
      for (final m in pattern.allMatches(File(path).readAsStringSync())) {
        allowed = [for (final t in m.group(1)!.split(',')) t.trim().replaceAll("'", '')];
      }
    }
    expect(allowed, isNotNull);
    expect(allowed, containsAll(['word', 'kana', 'kanji', 'grammar', 'conjugation', ...koreanCardTypes]));
  });
}
