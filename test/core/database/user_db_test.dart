import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/ids.dart';
import 'package:nihondx/core/study_day.dart';

void main() {
  late UserDb db;
  setUp(() => db = UserDb.memory());
  tearDown(() => db.close());

  test('natural ids are deterministic UUIDv5', () {
    expect(naturalId('bookmark:1358280'), naturalId('bookmark:1358280'));
    expect(naturalId('bookmark:1358280'), isNot(naturalId('bookmark:1358281')));
    expect(naturalId('lesson:x')[14], '5'); // version nibble
    expect(randomId(), isNot(randomId()));
  });

  test('device id is created once', () async {
    final id = await db.deviceId();
    expect(await db.deviceId(), id);
  });

  test('device settings are never marked for sync', () async {
    await db.setSetting('device.theme', 'dark');
    await db.setSetting('learning_level', '5');
    final rows = await db.select(db.userSettings).get();
    final status = {for (final r in rows) r.key: r.syncStatus};
    expect(status, {'device.theme': 0, 'learning_level': 1});
    expect(await db.setting('device.theme'), 'dark');
    expect(await db.setting('missing'), null);
  });

  test('lessons keep their best score', () async {
    await db.completeLesson('hiragana-u1-intro-0', score: .9);
    await db.completeLesson('hiragana-u1-intro-0', score: .8);
    await db.completeLesson('hiragana-u1-write');
    expect(await db.doneLessons(), {'hiragana-u1-intro-0', 'hiragana-u1-write'});
    final row = await (db.select(
      db.lessonProgress,
    )..where((t) => t.lessonId.equals('hiragana-u1-intro-0'))).getSingle();
    expect(row.score, .9);
    expect(row.id, naturalId('lesson:hiragana-u1-intro-0'));
  });

  test('daily stats add up per day and XP sums all days', () async {
    await db.addDailyStats('2026-10-09', xp: 30);
    await db.addDailyStats('2026-10-10', xp: 10, correctCount: 1);
    await db.addDailyStats('2026-10-10', xp: 15, correctCount: 1);
    expect(await db.totalXp(), 55);
    final today = await (db.select(db.dailyStats)..where((t) => t.date.equals('2026-10-10'))).getSingle();
    expect(today.correctCount, 2);
    expect(today.deviceId, await db.deviceId());
  });

  test('search history keeps the last 10, newest first, without duplicates', () async {
    for (var i = 0; i < 12; i++) {
      await db.addHistory('q$i', 'ja');
    }
    await db.addHistory('q5', 'ja');
    final history = await db.watchHistory('ja').first;
    expect(history.length, 10);
    expect(history.first, 'q5');
    expect(history.where((q) => q == 'q5').length, 1);
    expect(history, isNot(contains('q0')));
  });

  test('each study language keeps its own search history', () async {
    await db.addHistory('eat', 'ja');
    await db.addHistory('water', 'ko');
    for (var i = 0; i < 12; i++) {
      await db.addHistory('k$i', 'ko');
    }
    expect(await db.watchHistory('ja').first, ['eat']);
    expect(await db.watchHistory('ko').first, isNot(contains('eat')));
    // A full Korean history does not push out Japanese searches.
    expect(await db.watchHistory('ko').first, hasLength(10));
    await db.clearHistory('ko');
    expect(await db.watchHistory('ko').first, isEmpty);
    expect(await db.watchHistory('ja').first, ['eat']);
    await db.removeHistory('eat', 'ja');
    expect(await db.watchHistory('ja').first, isEmpty);
  });

  test('a bookmark toggled off and on is the same row', () async {
    await db.setBookmark(1358280, on: true, label: '食べる');
    await db.setBookmark(1358280, on: false, label: '食べる');
    expect(await db.watchBookmarks().first, isEmpty);
    await db.setBookmark(1358280, on: true, label: '食べる');
    final all = await db.select(db.bookmarks).get();
    expect(all.length, 1);
    expect(all.single.id, naturalId('bookmark:1358280'));
    expect(all.single.deletedAt, null);
    expect((await db.watchBookmarks().first).single.wordId, 1358280);
  });

  test('undo of a removed bookmark keeps its place in the list', () async {
    await db.setBookmark(1, on: true, label: 'a');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.setBookmark(2, on: true, label: 'b');
    await db.setBookmark(1, on: false, label: 'a');
    await db.setBookmark(1, on: true, label: 'a', restore: true);
    expect([for (final b in await db.watchBookmarks().first) b.wordId], [2, 1]);
    // Bookmarking again (not undo) moves it to the top.
    await db.setBookmark(1, on: false, label: 'a');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.setBookmark(1, on: true, label: 'a');
    expect([for (final b in await db.watchBookmarks().first) b.wordId], [1, 2]);
  });

  group('srs', () {
    const now = '2026-10-11T05:00:00.000Z';

    test('adding a card twice keeps one row; removing and re-adding keeps its history', () async {
      await db.addCard('word', '1358280', label: '食べる');
      await db.addCard('word', '1358280', label: '食べる');
      expect(await db.select(db.srsCards).get(), hasLength(1));
      final card = (await db.select(db.srsCards).get()).single;
      await db.saveReview(
        card,
        state: 'review',
        intervalDays: 1,
        ease: 2.5,
        reps: 1,
        lapses: 0,
        dueAt: '2026-10-12T05:00:00.000Z',
        rating: 3,
        studyDate: '2026-10-11',
      );
      await db.removeCard('word', '1358280');
      expect(await db.watchCardItems('word').first, isEmpty);
      await db.addCard('word', '1358280', label: '食べる');
      final back = (await db.select(db.srsCards).get()).single;
      expect(back.state, 'review');
      expect(back.reps, 1);
      expect(back.id, UserDb.cardId('word', '1358280', 'jp_to_meaning'));
    });

    test('a word can have a card per direction; removing drops both', () async {
      await db.addCard('word', '7', label: '水');
      await db.addCard('word', '7', label: '水', direction: 'meaning_to_jp');
      expect({for (final c in await db.select(db.srsCards).get()) c.direction}, {'jp_to_meaning', 'meaning_to_jp'});
      expect(await db.watchCardItems('word').first, {'7'});
      await db.removeCard('word', '7');
      expect([for (final c in await db.select(db.srsCards).get()) c.deletedAt], everyElement(isNotNull));
    });

    test('queue: learning before review, then new cards, within the limits', () async {
      for (final id in ['1', '2', '3', '4']) {
        await db.addCard('word', id, label: id);
      }
      final cards = {for (final c in await db.select(db.srsCards).get()) c.itemId: c};
      Future<void> set(String id, String state, String due) => db.saveReview(
        cards[id]!,
        state: state,
        intervalDays: 1,
        ease: 2.5,
        reps: 1,
        lapses: 0,
        dueAt: due,
        rating: 3,
        studyDate: '2026-10-11',
      );
      await set('1', 'review', '2026-10-10T00:00:00.000Z');
      await set('2', 'learning', '2026-10-11T04:59:00.000Z');
      await set('3', 'review', '2026-10-20T00:00:00.000Z'); // not due yet
      final q = await db.queue(nowIso: now, newLeft: 10, reviewLeft: 10);
      expect([for (final c in q) c.itemId], ['2', '1', '4']);
      expect(await db.queue(nowIso: now, newLeft: 0, reviewLeft: 1), hasLength(1));
      expect(await db.queue(nowIso: now, newLeft: -3, reviewLeft: -1), isEmpty);
      expect(await db.watchCardCounts(now).first, (due: 2, fresh: 1));
    });

    test('the queue and counts keep one language\'s card types', () async {
      const now = '2026-10-11T05:00:00.000Z';
      await db.addCard('kana', 'あ', label: 'あ');
      await db.addCard('hangul', 'ㄱ', label: 'ㄱ');
      await db.addCard('ko_word', '90000001', label: '물');
      const korean = ['hangul', 'ko_word'];
      final ko = await db.queue(nowIso: now, newLeft: 10, reviewLeft: 10, types: korean);
      expect([for (final c in ko) c.itemId], ['ㄱ', '90000001']);
      final ja = await db.queue(nowIso: now, newLeft: 10, reviewLeft: 10, types: korean, exceptTypes: true);
      expect([for (final c in ja) c.itemId], ['あ']);
      expect(await db.watchCardCounts(now, types: korean).first, (due: 0, fresh: 2));
      expect(await db.watchCardCounts(now, types: korean, exceptTypes: true).first, (due: 0, fresh: 1));
    });

    test('an answer writes a review log and today\'s stats', () async {
      await db.addCard('kana', 'あ', label: 'あ');
      final card = (await db.select(db.srsCards).get()).single;
      await db.saveReview(
        card,
        state: 'learning',
        intervalDays: 0.007,
        ease: 2.5,
        reps: 1,
        lapses: 0,
        dueAt: now,
        rating: 3,
        studyDate: '2026-10-11',
        durationMs: 4000,
        xp: 5,
      );
      final log = (await db.select(db.reviewLogs).get()).single;
      expect(log.prevState, 'new');
      expect(log.rating, 3);
      expect(await db.doneOn('2026-10-11'), (newCount: 1, reviewCount: 0));
      expect(await db.totalXp(), 5);
    });
  });

  test('day totals add up all devices; review accuracy comes from the log', () async {
    await db.addDailyStats('2026-10-10', xp: 10);
    await db.addDailyStats('2026-10-11', reviewCount: 3, newCount: 1, studyMs: 9000);
    // The same day studied on another device (pulled by sync).
    await db
        .into(db.dailyStats)
        .insert(
          DailyStatsCompanion.insert(
            date: '2026-10-11',
            deviceId: 'other-device',
            reviewCount: const Value(2),
            updatedAt: '2026-10-11T08:00:00.000Z',
          ),
        );
    final days = await db.watchDayTotals().first;
    expect([for (final d in days) d.date], ['2026-10-10', '2026-10-11']);
    expect(days.first.active, isTrue); // XP alone counts as activity
    expect(days.first.cards, 0);
    expect((days.last.cards, days.last.newCount, days.last.studyMs), (6, 1, 9000));

    await db.addCard('word', '1', label: '一');
    final card = (await db.select(db.srsCards).get()).single;
    for (final rating in [1, 3, 4]) {
      await db.saveReview(
        card,
        state: 'learning',
        intervalDays: 0,
        ease: 2.5,
        reps: 1,
        lapses: 0,
        dueAt: '2026-10-11T08:00:00.000Z',
        rating: rating,
        studyDate: '2026-10-11',
      );
    }
    expect((await db.watchReviewDays().first)['2026-10-11'], (answers: 3, correct: 2));
  });

  test('attempts come back oldest first per type', () async {
    await db.addAttempt(type: 'kana', itemId: '12354', correct: false, studyDate: '2026-10-10');
    await db.addAttempt(type: 'kanji', itemId: '19968', correct: true, studyDate: '2026-10-10');
    await db.addAttempt(type: 'kana', itemId: '12354', correct: true, studyDate: '2026-10-10');
    final kana = await db.attempts(const ['kana']);
    expect([for (final a in kana) a.correct], [0, 1]);
  });

  group('study date', () {
    test('a new day starts at 04:00 local time', () {
      expect(studyDate(DateTime(2026, 10, 10, 1, 30)), '2026-10-09');
      expect(studyDate(DateTime(2026, 10, 10, 3, 59)), '2026-10-09');
      expect(studyDate(DateTime(2026, 10, 10, 4)), '2026-10-10');
      expect(studyDate(DateTime(2026, 1, 1, 2)), '2025-12-31');
    });

    test('previous date crosses months and years', () {
      expect(previousDate('2026-03-01'), '2026-02-28');
      expect(previousDate('2026-01-01'), '2025-12-31');
    });
  });
}
