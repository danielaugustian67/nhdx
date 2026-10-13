import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../ids.dart';

part 'user_db.g.dart';

// user.db (PRD §9.C): the only read-write database. Times are UTC ISO-8601
// text, as in the cloud tables; sync_status 0 = synced, 1 = pending.
// The whole v1.0 → v2.0 schema exists from version 1 so sync (Fase 4) and
// later features do not need large migrations.

/// Columns every synced table with a natural key has.
mixin _Synced on Table {
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();
}

// ---- Natural-key tables (UUIDv5 ids) ----

class Bookmarks extends Table with _Synced {
  TextColumn get id => text()();
  IntColumn get wordId => integer().unique()();
  TextColumn get labelSnapshot => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class SrsCards extends Table with _Synced {
  TextColumn get id => text()();
  TextColumn get cardType => text()();
  TextColumn get itemId => text()();
  TextColumn get direction => text().withDefault(const Constant('jp_to_meaning'))();
  TextColumn get labelSnapshot => text()();
  TextColumn get state => text()();
  TextColumn get dueAt => text().nullable()();
  RealColumn get intervalDays => real().withDefault(const Constant(0))();
  RealColumn get ease => real().withDefault(const Constant(2.5))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get isOrphan => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {cardType, itemId, direction},
  ];
}

@DataClassName('LessonProgressRow')
class LessonProgress extends Table with _Synced {
  TextColumn get id => text()();
  TextColumn get lessonId => text().unique()();
  TextColumn get status => text()();
  RealColumn get score => real().nullable()();
  TextColumn get completedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReadingProgressRow')
class ReadingProgress extends Table with _Synced {
  TextColumn get id => text()();
  TextColumn get storyId => text().unique()();
  TextColumn get status => text()();
  RealColumn get score => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class UserAchievements extends Table {
  TextColumn get id => text()();
  TextColumn get achievementId => text().unique()();
  TextColumn get unlockedAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Keys starting with `device.` stay on this device (theme, font size, …).
class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  TextColumn get updatedAt => text()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {key};
}

// ---- Append-only tables (UUIDv4 ids) ----

class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text()();
  IntColumn get rating => integer()();
  TextColumn get reviewedAt => text()();
  TextColumn get studyDate => text()();
  TextColumn get prevState => text().nullable()();
  RealColumn get prevInterval => real().nullable()();
  RealColumn get newInterval => real().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseType => text()();
  TextColumn get itemId => text().nullable()();
  IntColumn get correct => integer()();
  TextColumn get answeredAt => text()();
  TextColumn get studyDate => text()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class GameScores extends Table {
  TextColumn get id => text()();
  TextColumn get game => text()();
  IntColumn get score => integer()();
  RealColumn get accuracy => real().nullable()();
  TextColumn get playedAt => text()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class StreakFreezes extends Table {
  TextColumn get id => text()();
  TextColumn get coveredDate => text()();
  TextColumn get createdAt => text()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class CoinLedger extends Table {
  TextColumn get id => text()();
  IntColumn get delta => integer()();
  TextColumn get reason => text()();
  TextColumn get refId => text().nullable()();
  TextColumn get createdAt => text()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---- Per device ----

class DailyStats extends Table {
  TextColumn get date => text()();
  TextColumn get deviceId => text()();
  IntColumn get newCount => integer().withDefault(const Constant(0))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get studyMs => integer().withDefault(const Constant(0))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  TextColumn get updatedAt => text()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {date, deviceId};
}

// ---- Instances (v2.0) ----

class IslandInventory extends Table with _Synced {
  TextColumn get id => text()();
  TextColumn get itemId => text()();
  RealColumn get x => real().nullable()();
  RealColumn get y => real().nullable()();
  IntColumn get placed => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---- Local only ----

class StreakState extends Table {
  // Drift's CHECK syntax refers to the column itself; a single-row table.
  // ignore: recursive_getters
  IntColumn get id => integer().check(id.equals(1))();
  IntColumn get current => integer().nullable()();
  IntColumn get longest => integer().nullable()();
  TextColumn get lastActiveDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Last pull per table, in SERVER time (PRD §8).
class SyncState extends Table {
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get lastPullAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {tableName_};
}

class ContentPacks extends Table {
  TextColumn get id => text()();
  TextColumn get version => text().nullable()();
  TextColumn get installedAt => text().nullable()();
  TextColumn get checksum => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  TextColumn get searchedAt => text()();
}

String nowUtc() => DateTime.now().toUtc().toIso8601String();

/// One study date over all devices.
class DayTotals {
  const DayTotals({required this.date, this.newCount = 0, this.reviewCount = 0, this.studyMs = 0, this.xp = 0});

  final String date;
  final int newCount;
  final int reviewCount;
  final int studyMs;
  final int xp;

  /// Cards answered: what the daily goal counts (PRD F8).
  int get cards => newCount + reviewCount;

  /// Any learning at all (cards, lessons, games) keeps the streak.
  bool get active => cards > 0 || xp > 0;
}

@DriftDatabase(
  tables: [
    Bookmarks,
    SrsCards,
    LessonProgress,
    ReadingProgress,
    UserAchievements,
    UserSettings,
    ReviewLogs,
    ExerciseAttempts,
    GameScores,
    StreakFreezes,
    CoinLedger,
    DailyStats,
    IslandInventory,
    StreakState,
    LocalMeta,
    SyncState,
    ContentPacks,
    SearchHistory,
  ],
)
class UserDb extends _$UserDb {
  UserDb(super.e);

  factory UserDb.open(File file) => UserDb(NativeDatabase.createInBackground(file));

  factory UserDb.memory() => UserDb(NativeDatabase.memory());

  /// Bump with every schema change; add a step in [migration] and run
  /// `dart run drift_dev make-migrations` to dump the schema and generate
  /// the migration tests (development_plan Fase 0).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---- local_meta ----

  Future<String?> meta(String key) async =>
      (await (select(localMeta)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setMeta(String key, String? value) =>
      into(localMeta).insertOnConflictUpdate(LocalMetaCompanion.insert(key: key, value: Value(value)));

  /// Random id of this installation, created on first use (PRD §8).
  Future<String> deviceId() async {
    final existing = await meta('device_id');
    if (existing != null) return existing;
    final id = randomId();
    await setMeta('device_id', id);
    return id;
  }

  /// Ties this install's data to the signed-in account (PRD §8 "Login &
  /// pemulihan"). The first account keeps what is already here; a different
  /// account starts empty, so nobody sees someone else's progress. Returns
  /// whether data was cleared.
  Future<bool> claimFor(String userId) => transaction(() async {
    final owner = await meta('owner_user_id');
    if (owner == userId) return false;
    if (owner != null) await clearAccountData();
    await setMeta('owner_user_id', userId);
    return owner != null;
  });

  /// Removes everything that belongs to an account. Kept: this phone's own
  /// settings (`device.*`), the installation id, installed content packs and
  /// `owner_user_id`.
  Future<void> clearAccountData() => transaction(() async {
    await (delete(localMeta)..where((m) => m.key.equals('last_sync_at'))).go();
    for (final table in allTables) {
      if (table == localMeta || table == contentPacks) continue;
      if (table == userSettings) {
        await (delete(userSettings)..where((s) => s.key.like('device.%').not())).go();
      } else {
        await delete(table).go();
      }
    }
  });

  /// Whether anything was learned or saved here: an install that already has
  /// data skips onboarding (PRD F9).
  Future<bool> hasLearningData() async {
    final row = await customSelect(
      'SELECT EXISTS (SELECT 1 FROM srs_cards) OR EXISTS (SELECT 1 FROM lesson_progress) '
      'OR EXISTS (SELECT 1 FROM bookmarks) OR EXISTS (SELECT 1 FROM game_scores) AS any_data',
    ).getSingle();
    return row.read<bool>('any_data');
  }

  // ---- settings ----

  Future<String?> setting(String key) async =>
      (await (select(userSettings)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String? value) => into(userSettings).insertOnConflictUpdate(
    UserSettingsCompanion.insert(
      key: key,
      value: Value(value),
      updatedAt: nowUtc(),
      // Device settings are never pushed.
      syncStatus: Value(key.startsWith('device.') ? 0 : 1),
    ),
  );

  // ---- lesson progress ----

  Future<Set<String>> doneLessons() async {
    final rows = await (select(lessonProgress)..where((t) => t.status.equals('done') & t.deletedAt.isNull())).get();
    return {for (final r in rows) r.lessonId};
  }

  /// Marks a lesson as started (`in_progress`) unless it already has a row,
  /// so a finished lesson never goes back.
  Future<void> startLesson(String lessonId) async {
    final now = nowUtc();
    await into(lessonProgress).insert(
      LessonProgressCompanion.insert(
        id: naturalId('lesson:$lessonId'),
        lessonId: lessonId,
        status: 'in_progress',
        updatedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Marks a lesson done; a better score replaces a worse one.
  Future<void> completeLesson(String lessonId, {double? score}) async {
    final now = nowUtc();
    final existing = await (select(lessonProgress)..where((t) => t.lessonId.equals(lessonId))).getSingleOrNull();
    final best = [?existing?.score, ?score].fold<double?>(null, (a, b) => a == null || b > a ? b : a);
    await into(lessonProgress).insertOnConflictUpdate(
      LessonProgressCompanion.insert(
        id: naturalId('lesson:$lessonId'),
        lessonId: lessonId,
        status: 'done',
        score: Value(best),
        completedAt: Value(existing?.completedAt ?? now),
        updatedAt: now,
        deletedAt: const Value(null),
        syncStatus: const Value(1),
      ),
    );
  }

  // ---- activity ----

  /// Adds to today's row of this device in daily_stats.
  Future<void> addDailyStats(
    String date, {
    int xp = 0,
    int newCount = 0,
    int reviewCount = 0,
    int correctCount = 0,
    int studyMs = 0,
  }) async {
    final device = await deviceId();
    await customStatement(
      'INSERT INTO daily_stats (date, device_id, new_count, review_count, correct_count, study_ms, xp, '
      'updated_at, sync_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1) '
      'ON CONFLICT (date, device_id) DO UPDATE SET '
      'new_count = new_count + excluded.new_count, review_count = review_count + excluded.review_count, '
      'correct_count = correct_count + excluded.correct_count, study_ms = study_ms + excluded.study_ms, '
      'xp = xp + excluded.xp, updated_at = excluded.updated_at, sync_status = 1',
      [date, device, newCount, reviewCount, correctCount, studyMs, xp, nowUtc()],
    );
  }

  /// XP over all days and devices.
  Future<int> totalXp() async {
    final sum = dailyStats.xp.sum();
    final row = await (selectOnly(dailyStats)..addColumns([sum])).getSingle();
    return row.read(sum) ?? 0;
  }

  Future<void> addAttempt({
    required String type,
    required String itemId,
    required bool correct,
    required String studyDate,
  }) => into(exerciseAttempts).insert(
    ExerciseAttemptsCompanion.insert(
      id: randomId(),
      exerciseType: type,
      itemId: Value(itemId),
      correct: correct ? 1 : 0,
      answeredAt: nowUtc(),
      studyDate: studyDate,
    ),
  );

  /// Attempts of the given exercise types, oldest first.
  Future<List<ExerciseAttempt>> attempts(Iterable<String> types) =>
      (select(exerciseAttempts)
            ..where((t) => t.exerciseType.isIn(types))
            ..orderBy([(t) => OrderingTerm(expression: t.answeredAt)]))
          .get();

  Future<void> addGameScore(String game, {required int score, double? accuracy}) => into(gameScores).insert(
    GameScoresCompanion.insert(id: randomId(), game: game, score: score, accuracy: Value(accuracy), playedAt: nowUtc()),
  );

  // ---- search history (local only, last 10) ----

  static const historySize = 10;

  Stream<List<String>> watchHistory() {
    final q = select(searchHistory)
      ..orderBy([(t) => OrderingTerm.desc(t.searchedAt), (t) => OrderingTerm.desc(t.id)])
      ..limit(historySize);
    return q.watch().map((rows) => [for (final r in rows) r.query]);
  }

  Future<void> addHistory(String query) => transaction(() async {
    await (delete(searchHistory)..where((t) => t.query.equals(query))).go();
    await into(searchHistory).insert(SearchHistoryCompanion.insert(query: query, searchedAt: nowUtc()));
    await customStatement(
      'DELETE FROM search_history WHERE id NOT IN '
      '(SELECT id FROM search_history ORDER BY searched_at DESC, id DESC LIMIT $historySize)',
    );
  });

  Future<void> removeHistory(String query) => (delete(searchHistory)..where((t) => t.query.equals(query))).go();

  Future<void> clearHistory() => delete(searchHistory).go();

  // ---- bookmarks ----

  /// Live bookmarks, newest first.
  Stream<List<Bookmark>> watchBookmarks() =>
      (select(bookmarks)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Adds or soft-deletes a bookmark. Re-adding keeps the same row (and id),
  /// so the cloud never sees two rows for one word (PRD §8). [restore] is the
  /// undo of a delete: the bookmark keeps its place in the newest-first list.
  Future<void> setBookmark(int wordId, {required bool on, required String label, bool restore = false}) async {
    final now = nowUtc();
    final existing = await (select(bookmarks)..where((t) => t.wordId.equals(wordId))).getSingleOrNull();
    await into(bookmarks).insertOnConflictUpdate(
      BookmarksCompanion.insert(
        id: naturalId('bookmark:$wordId'),
        wordId: wordId,
        labelSnapshot: label,
        createdAt: existing == null || (on && !restore) ? now : existing.createdAt,
        updatedAt: now,
        deletedAt: Value(on ? null : now),
        syncStatus: const Value(1),
      ),
    );
  }

  // ---- SRS (PRD F5) ----

  static String cardId(String cardType, String itemId, String direction) =>
      naturalId('srs:$cardType:$itemId:$direction');

  /// Adds a new card unless it exists; a removed card comes back with its
  /// history (same row, PRD §8).
  Future<void> addCard(
    String cardType,
    String itemId, {
    required String label,
    String direction = 'jp_to_meaning',
  }) async {
    final id = cardId(cardType, itemId, direction);
    final existing = await (select(srsCards)..where((t) => t.id.equals(id))).getSingleOrNull();
    final now = nowUtc();
    if (existing != null) {
      if (existing.deletedAt == null) return;
      await (update(srsCards)..where((t) => t.id.equals(id))).write(
        SrsCardsCompanion(deletedAt: const Value(null), updatedAt: Value(now), syncStatus: const Value(1)),
      );
      return;
    }
    await into(srsCards).insert(
      SrsCardsCompanion.insert(
        id: id,
        cardType: cardType,
        itemId: itemId,
        direction: Value(direction),
        labelSnapshot: label,
        state: 'new',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Removes the item's cards in every direction (one "Sudah di belajar"
  /// toggle per word).
  Future<void> removeCard(String cardType, String itemId) =>
      (update(srsCards)..where((t) => t.cardType.equals(cardType) & t.itemId.equals(itemId) & t.deletedAt.isNull()))
          .write(SrsCardsCompanion(deletedAt: Value(nowUtc()), updatedAt: Value(nowUtc()), syncStatus: const Value(1)));

  /// Item ids of the live cards of one type ("Sudah di belajar").
  Stream<Set<String>> watchCardItems(String cardType) =>
      (select(srsCards)..where((t) => t.cardType.equals(cardType) & t.deletedAt.isNull())).watch().map(
        (rows) => {for (final r in rows) r.itemId},
      );

  /// Cards of [types] (or, with [exceptTypes], of every other type); all
  /// cards when [types] is null.
  Expression<bool> _ofTypes(List<String>? types, bool exceptTypes) => types == null
      ? const Constant(true)
      : (exceptTypes ? srsCards.cardType.isNotIn(types) : srsCards.cardType.isIn(types));

  /// Today's queue: due cards (learning first, then oldest due), then new
  /// cards in the order they were added. [newLeft] / [reviewLeft] are what
  /// remains of the daily limits; orphans are skipped (PRD F5). [types] and
  /// [exceptTypes] keep one language's cards.
  Future<List<SrsCard>> queue({
    required String nowIso,
    required int newLeft,
    required int reviewLeft,
    List<String>? types,
    bool exceptTypes = false,
  }) async {
    final live = srsCards.deletedAt.isNull() & srsCards.isOrphan.equals(0) & _ofTypes(types, exceptTypes);
    final due =
        await (select(srsCards)
              ..where((t) => live & t.state.equals('new').not() & t.dueAt.isSmallerOrEqualValue(nowIso))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: CustomExpression<int>("CASE WHEN state IN ('learning', 'relearning') THEN 0 ELSE 1 END"),
                ),
                (t) => OrderingTerm(expression: t.dueAt),
              ])
              ..limit(reviewLeft < 0 ? 0 : reviewLeft))
            .get();
    final fresh =
        await (select(srsCards)
              ..where((t) => live & t.state.equals('new'))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
              ..limit(newLeft < 0 ? 0 : newLeft))
            .get();
    return [...due, ...fresh];
  }

  /// Cards due by [nowIso] plus new cards (for badges), ignoring limits;
  /// [types] and [exceptTypes] as in [queue].
  Stream<({int due, int fresh})> watchCardCounts(String nowIso, {List<String>? types, bool exceptTypes = false}) {
    final count = srsCards.id.count();
    final isNew = srsCards.state.equals('new');
    final live = srsCards.deletedAt.isNull() & srsCards.isOrphan.equals(0) & _ofTypes(types, exceptTypes);
    final dueQ = selectOnly(srsCards)
      ..addColumns([count])
      ..where(live & isNew.not() & srsCards.dueAt.isSmallerOrEqualValue(nowIso));
    final newQ = selectOnly(srsCards)
      ..addColumns([count])
      ..where(live & isNew);
    return dueQ.watchSingle().asyncMap((d) async {
      final n = await newQ.getSingle();
      return (due: d.read(count) ?? 0, fresh: n.read(count) ?? 0);
    });
  }

  /// New cards and reviews already done on [date] on this device.
  Future<({int newCount, int reviewCount})> doneOn(String date) async {
    final rows = await (select(dailyStats)..where((t) => t.date.equals(date))).get();
    return (newCount: rows.fold(0, (a, r) => a + r.newCount), reviewCount: rows.fold(0, (a, r) => a + r.reviewCount));
  }

  // ---- progress (PRD F8) ----

  /// Activity per study date, summed over all devices, oldest first.
  Stream<List<DayTotals>> watchDayTotals() =>
      customSelect(
        'SELECT date, SUM(new_count) AS n, SUM(review_count) AS r, SUM(study_ms) AS ms, SUM(xp) AS xp '
        'FROM daily_stats GROUP BY date ORDER BY date',
        readsFrom: {dailyStats},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            DayTotals(
              date: r.read<String>('date'),
              newCount: r.read<int>('n'),
              reviewCount: r.read<int>('r'),
              studyMs: r.read<int>('ms'),
              xp: r.read<int>('xp'),
            ),
        ],
      );

  /// Review answers and how many were not "Again", per study date. Game
  /// answers are left out, so this is the SRS accuracy.
  Stream<Map<String, ({int answers, int correct})>> watchReviewDays() =>
      customSelect(
        'SELECT study_date AS d, COUNT(*) AS a, SUM(rating > 1) AS c FROM review_logs GROUP BY study_date',
        readsFrom: {reviewLogs},
      ).watch().map(
        (rows) => {for (final r in rows) r.read<String>('d'): (answers: r.read<int>('a'), correct: r.read<int>('c'))},
      );

  Stream<Set<String>> watchFreezeDates() =>
      select(streakFreezes).watch().map((rows) => {for (final r in rows) r.coveredDate});

  Stream<String?> watchSetting(String key) =>
      (select(userSettings)..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  /// The stored values of [keys] (missing keys are absent), re-emitted when
  /// any of them changes.
  Stream<Map<String, String?>> watchSettings(Iterable<String> keys) => (select(
    userSettings,
  )..where((t) => t.key.isIn(keys))).watch().map((rows) => {for (final r in rows) r.key: r.value});

  Future<Map<String, String?>> settings(Iterable<String> keys) async => {
    for (final r in await (select(userSettings)..where((t) => t.key.isIn(keys))).get()) r.key: r.value,
  };

  /// Cards that are not deleted, for statistics.
  Stream<List<SrsCard>> watchLiveCards() => (select(srsCards)..where((t) => t.deletedAt.isNull())).watch();

  /// Stores one answer: the card's new schedule, an append-only review log
  /// and today's stats, in one transaction.
  Future<void> saveReview(
    SrsCard card, {
    required String state,
    required double intervalDays,
    required double ease,
    required int reps,
    required int lapses,
    required String dueAt,
    required int rating,
    required String studyDate,
    int? durationMs,
    int xp = 0,
  }) => transaction(() async {
    final now = nowUtc();
    await (update(srsCards)..where((t) => t.id.equals(card.id))).write(
      SrsCardsCompanion(
        state: Value(state),
        intervalDays: Value(intervalDays),
        ease: Value(ease),
        reps: Value(reps),
        lapses: Value(lapses),
        dueAt: Value(dueAt),
        updatedAt: Value(now),
        syncStatus: const Value(1),
      ),
    );
    await into(reviewLogs).insert(
      ReviewLogsCompanion.insert(
        id: randomId(),
        cardId: card.id,
        rating: rating,
        reviewedAt: now,
        studyDate: studyDate,
        prevState: Value(card.state),
        prevInterval: Value(card.intervalDays),
        newInterval: Value(intervalDays),
        durationMs: Value(durationMs),
      ),
    );
    await addDailyStats(
      studyDate,
      xp: xp,
      newCount: card.state == 'new' ? 1 : 0,
      reviewCount: card.state == 'new' ? 0 : 1,
      correctCount: rating > 1 ? 1 : 0,
      studyMs: durationMs ?? 0,
    );
  });
}
