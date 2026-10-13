import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/features/sync/sync_engine.dart';

import 'fake_cloud.dart';

void main() {
  late FakeCloud cloud;
  final dbs = <UserDb>[];

  // Each test plays two phones, each with its own in-memory user.db.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => cloud = FakeCloud());
  tearDown(() async {
    for (final db in dbs) {
      await db.close();
    }
    dbs.clear();
  });

  UserDb device() {
    final db = UserDb.memory();
    dbs.add(db);
    return db;
  }

  SyncEngine engine(UserDb db, {DateTime Function()? clock}) => SyncEngine(db, cloud, clock: clock);

  Future<SrsCard> card(UserDb db, String item) async =>
      (await db.select(db.srsCards).get()).firstWhere((c) => c.itemId == item);

  test('pushes pending rows once; device settings stay on the phone', () async {
    final db = device();
    await db.setBookmark(1358280, on: true, label: '食べる');
    await db.setSetting('learning_level', 'n5');
    await db.setSetting('device.theme', 'light');
    await db.addCard('word', '1358280', label: '食べる');
    await db.addDailyStats('2026-10-11', xp: 10, newCount: 1);
    await db.addAttempt(type: 'kana_quiz', itemId: 'あ', correct: true, studyDate: '2026-10-11');

    final sync = engine(db);
    expect(await sync.pendingCount(), 5);
    await sync.push();
    expect(await sync.pendingCount(), 0);

    expect(cloud.rows('user_settings').map((r) => r['key']), ['learning_level']);
    expect(cloud.rows('user_settings').single['value'], 'n5');
    expect(cloud.rows('user_bookmarks').single['word_id'], 1358280);
    expect(cloud.rows('user_srs_cards').single['is_orphan'], false);
    expect(cloud.rows('user_exercise_attempts').single['correct'], true);
    expect(cloud.rows('user_daily_stats').single['xp'], 10);
    expect(cloud.rows('user_bookmarks').single['client_updated_at'], isNotNull);
  });

  test('a row changed during its push stays pending', () async {
    final db = device();
    await db.setSetting('learning_level', 'n5');
    cloud.duringPush = () async {
      cloud.duringPush = null;
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.setSetting('learning_level', 'n4');
    };
    final sync = engine(db);
    await sync.push();
    expect(await sync.pendingCount(), 1, reason: 'n4 was not pushed yet');
    await sync.push();
    expect(cloud.rows('user_settings').single['value'], 'n4');
    expect(await sync.pendingCount(), 0);
  });

  test('the same bookmark made offline on two phones is one row', () async {
    final a = device(), b = device();
    await a.setBookmark(42, on: true, label: 'x');
    await b.setBookmark(42, on: true, label: 'x');
    await engine(a).sync();
    await engine(b).sync();
    await engine(a).sync();
    expect(cloud.rows('user_bookmarks'), hasLength(1));
    expect(await b.select(b.bookmarks).get(), hasLength(1));
  });

  test('a card with more reviews wins on both phones', () async {
    final a = device(), b = device();
    await a.addCard('word', '7', label: 'w');
    await engine(a).sync();
    await engine(b).sync();
    expect((await card(b, '7')).state, 'new');

    // Phone A reviews twice; phone B, offline, once (and later in time).
    final c = await card(a, '7');
    for (final reps in [1, 2]) {
      await a.saveReview(
        await card(a, '7'),
        state: 'review',
        intervalDays: reps * 3.0,
        ease: 2.5,
        reps: reps,
        lapses: 0,
        dueAt: '2026-10-2${reps}T00:00:00.000Z',
        rating: 3,
        studyDate: '2026-10-11',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await b.saveReview(
      await card(b, c.itemId),
      state: 'learning',
      intervalDays: 0,
      ease: 2.5,
      reps: 1,
      lapses: 0,
      dueAt: '2026-10-11T10:00:00.000Z',
      rating: 1,
      studyDate: '2026-10-11',
    );

    await engine(a).sync();
    await engine(b).sync();
    await engine(a).sync();
    for (final db in [a, b]) {
      final synced = await card(db, '7');
      expect(synced.reps, 2);
      expect(synced.intervalDays, 6);
      expect(synced.syncStatus, 0);
    }
    expect(cloud.rows('user_review_logs'), hasLength(3), reason: 'every answer is kept');
  });

  test('a finished lesson is not undone by an older start elsewhere', () async {
    final a = device(), b = device();
    await b.startLesson('kana-1');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await a.completeLesson('kana-1', score: 0.9);
    await engine(a).sync();
    await engine(b).sync();
    final row = await b.select(b.lessonProgress).getSingle();
    expect(row.status, 'done');
    expect(row.score, 0.9);
  });

  test('a new install gets everything back without duplicates', () async {
    final a = device();
    await a.setBookmark(1, on: true, label: 'a');
    await a.setBookmark(2, on: true, label: 'b');
    await a.setBookmark(2, on: false, label: 'b');
    await a.addCard('kana', 'あ', label: 'あ');
    await a.setSetting('learning_level', 'n4');
    await a.addDailyStats('2026-10-10', xp: 30, reviewCount: 3);
    await a.addGameScore('speed', score: 12);
    await engine(a).sync();

    final fresh = device();
    final sync = engine(fresh);
    await sync.sync(full: true);
    await sync.sync();
    expect(await sync.pendingCount(), 0);
    expect((await fresh.watchBookmarks().first).map((b) => b.wordId), [1], reason: 'the deleted one stays deleted');
    expect(await fresh.select(fresh.bookmarks).get(), hasLength(2));
    expect(await fresh.setting('learning_level'), 'n4');
    expect(await fresh.totalXp(), 30);
    expect(await fresh.select(fresh.gameScores).get(), hasLength(1));
    expect((await card(fresh, 'あ')).createdAt, (await card(a, 'あ')).createdAt, reason: 'times keep the local format');
  });

  test('two phones studying the same day add up', () async {
    final a = device(), b = device();
    await a.addDailyStats('2026-10-11', xp: 10, newCount: 2);
    await b.addDailyStats('2026-10-11', xp: 5, reviewCount: 4);
    await engine(a).sync();
    await engine(b).sync();
    await engine(a).sync();
    for (final db in [a, b]) {
      final day = (await db.watchDayTotals().first).single;
      expect((day.xp, day.cards), (15, 6));
    }
  });

  test('pulls only what changed since last time', () async {
    final a = device(), b = device();
    await a.setBookmark(1, on: true, label: 'a');
    await engine(a).sync();
    final sync = engine(b);
    await sync.sync();
    final cursor = await b
        .customSelect("SELECT last_pull_at FROM sync_state WHERE table_name = 'user_bookmarks'")
        .getSingle();
    expect(cursor.read<String>('last_pull_at'), endsWith('Z'));

    cloud.advance(const Duration(hours: 1));
    await a.setBookmark(1, on: false, label: 'a');
    await engine(a).sync();
    await sync.pull();
    expect(await b.watchBookmarks().first, isEmpty);
  });

  test('after more than 30 days away, rows purged in the cloud go here too', () async {
    final a = device(), b = device();
    await a.setBookmark(1, on: true, label: 'a');
    await a.setBookmark(2, on: true, label: 'b');
    await engine(a).sync();
    var now = DateTime.utc(2026, 10, 1, 1);
    final sync = engine(b, clock: () => now);
    await sync.sync();
    // Unsynced work here is never dropped.
    await b.setBookmark(3, on: true, label: 'c');

    // Bookmark 2 was deleted elsewhere and purged after 30 days.
    cloud.tables['user_bookmarks']!.removeWhere((_, r) => r['word_id'] == 2);
    now = now.add(const Duration(days: 40));
    cloud.advance(const Duration(days: 40));
    await sync.pull();
    expect((await b.watchBookmarks().first).map((r) => r.wordId).toSet(), {1, 3});
  });

  test('a table the cloud rejects does not hold back the others', () async {
    final a = device(), b = device();
    await b.setSetting('daily_goal', '40');
    await engine(b).sync();

    await a.addCard('hangul', 'ㄱ', label: 'ㄱ');
    await a.setBookmark(7, on: true, label: 'w');
    await a.addDailyStats('2026-10-11', xp: 10, newCount: 1);
    await a.setSetting('learning_level', 'n5');
    cloud.rejected.add('sync_push_srs_cards');
    final sync = engine(a);
    await expectLater(sync.sync(), throwsException);

    // Tables before and after the cards went up, the other phone's goal
    // came down…
    expect(cloud.rows('user_bookmarks').single['word_id'], 7);
    expect(cloud.rows('user_daily_stats').single['xp'], 10);
    expect(cloud.rows('user_settings').map((r) => r['key']), containsAll(['learning_level', 'daily_goal']));
    expect(await a.setting('daily_goal'), '40');
    // …and the rejected card waits for the next try.
    expect(await sync.pendingCount(), 1);
    cloud.rejected.clear();
    await sync.sync();
    expect(await sync.pendingCount(), 0);
    expect(cloud.rows('user_srs_cards').single['card_type'], 'hangul');
  });

  test('offline leaves everything pending', () async {
    final db = device();
    await db.setSetting('learning_level', 'n5');
    cloud.offline = true;
    final sync = engine(db);
    await expectLater(sync.sync(), throwsException);
    expect(await sync.pendingCount(), 1);
  });

  test('a pending local change that is newer survives a pull', () async {
    final a = device(), b = device();
    await a.setSetting('daily_goal', '20');
    await engine(a).sync();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await b.setSetting('daily_goal', '40');
    await engine(b).pull();
    expect(await b.setting('daily_goal'), '40');
    await engine(b).push();
    await engine(a).sync();
    expect(await a.setting('daily_goal'), '40');
  });

  test('a removed card comes back on the other phone', () async {
    final a = device(), b = device();
    await a.addCard('word', '9', label: 'w');
    await engine(a).sync();
    await engine(b).sync();
    await a.removeCard('word', '9');
    await engine(a).sync();
    await engine(b).sync();
    expect(await b.watchCardItems('word').first, isEmpty);

    await b.addCard('word', '9', label: 'w');
    await engine(b).sync();
    await engine(a).sync();
    expect(await a.watchCardItems('word').first, {'9'});
    expect(
      await (a.select(a.srsCards)..where((c) => c.syncStatus.equals(1))).get(),
      isEmpty,
      reason: 'nothing left to push',
    );
  });
}
