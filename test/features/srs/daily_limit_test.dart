import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/study_day.dart';
import 'package:nihondx/features/srs/srs_providers.dart';

void main() {
  late UserDb db;
  setUp(() => db = UserDb.memory());
  tearDown(() => db.close());

  Future<void> learn(SrsCard card) => db.saveReview(
    card,
    state: 'review',
    intervalDays: 1,
    ease: 2.5,
    reps: 1,
    lapses: 0,
    dueAt: '2099-01-01T00:00:00Z',
    rating: 3,
    studyDate: todayStudyDate(),
  );

  test('new cards learned today use up the daily limit', () async {
    expect(await newLeftToday(db), SrsLimits.defaultNew);
    await addWordCards(db, [for (var i = 0; i < 12; i++) (id: i, label: '語$i')]);
    final cards = await db.select(db.srsCards).get();
    for (final c in cards.take(3)) {
      await learn(c);
    }
    expect(await newLeftToday(db), SrsLimits.defaultNew - 3);

    // A higher limit in Settings lets more in today.
    await db.setSetting(SrsLimits.newKey, '20');
    expect(await newLeftToday(db), 17);

    for (final c in cards.skip(3)) {
      await learn(c);
    }
    await db.setSetting(SrsLimits.newKey, '5');
    // Never below zero, even past the limit.
    expect(await newLeftToday(db), 0);
  });

  test('limits fall back to the defaults for missing or unknown values', () {
    expect(SrsLimits.parse(const {}).newPerDay, SrsLimits.defaultNew);
    expect(SrsLimits.parse(const {SrsLimits.newKey: '7'}).newPerDay, SrsLimits.defaultNew);
    final set = SrsLimits.parse(const {SrsLimits.newKey: '15', SrsLimits.reviewsKey: '200'});
    expect((set.newPerDay, set.reviewsPerDay), (15, 200));
  });
}
