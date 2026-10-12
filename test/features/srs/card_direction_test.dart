import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/features/srs/srs_providers.dart';

void main() {
  late UserDb db;
  setUp(() => db = UserDb.memory());
  tearDown(() => db.close());

  Future<Set<String>> directions() async => {for (final c in await db.select(db.srsCards).get()) c.direction};

  test('new word cards follow the direction setting (default Japanese → meaning)', () async {
    await addWordCards(db, [(id: 1, label: '水')]);
    expect(await directions(), {'jp_to_meaning'});

    await db.setSetting(CardDirection.settingKey, CardDirection.meaningToJp.value);
    await addWordCards(db, [(id: 2, label: '火')]);
    final two = await db.select(db.srsCards).get();
    expect(two.firstWhere((c) => c.itemId == '2').direction, 'meaning_to_jp');

    await db.setSetting(CardDirection.settingKey, CardDirection.both.value);
    await addWordCards(db, [(id: 3, label: '木')]);
    final three = [
      for (final c in await db.select(db.srsCards).get())
        if (c.itemId == '3') c.direction,
    ];
    expect(three.toSet(), {'jp_to_meaning', 'meaning_to_jp'});
  });

  test('unknown setting values fall back to the default', () {
    expect(CardDirection.parse(null), CardDirection.jpToMeaning);
    expect(CardDirection.parse('sideways'), CardDirection.jpToMeaning);
    expect(CardDirection.parse('both').cardDirections, ['jp_to_meaning', 'meaning_to_jp']);
  });
}
