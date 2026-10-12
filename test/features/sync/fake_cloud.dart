import 'package:nihondx/features/sync/sync_remote.dart';

/// An in-memory stand-in for the Supabase tables and push RPCs, with the same
/// conflict rules as `supabase/migrations/*_sync_push_rpcs.sql`.
class FakeCloud implements SyncRemote {
  final tables = <String, Map<String, Row>>{};
  var _tick = DateTime.utc(2026, 10, 1);
  bool offline = false;

  /// Runs during a push, after the rows were read and before they are marked
  /// synced (to change a row "while" it is being pushed).
  Future<void> Function()? duringPush;

  static const _rpcTable = {
    'sync_push_settings': ('user_settings', ['key']),
    'sync_push_bookmarks': ('user_bookmarks', ['id']),
    'sync_push_srs_cards': ('user_srs_cards', ['id']),
    'sync_push_lesson_progress': ('user_lesson_progress', ['id']),
    'sync_push_daily_stats': ('user_daily_stats', ['date', 'device_id']),
    'sync_push_review_logs': ('user_review_logs', ['id']),
    'sync_push_exercise_attempts': ('user_exercise_attempts', ['id']),
    'sync_push_game_scores': ('user_game_scores', ['id']),
    'sync_push_streak_freezes': ('user_streak_freezes', ['id']),
  };

  /// Server time moves on with every write, like `now()` in the trigger.
  String _now() => (_tick = _tick.add(const Duration(seconds: 1))).toIso8601String().replaceFirst('Z', '+00:00');

  void advance(Duration d) => _tick = _tick.add(d);

  List<Row> rows(String table) => [...?tables[table]?.values];

  @override
  Future<void> push(String rpc, List<Row> rows) async {
    if (offline) throw Exception('SocketException: offline');
    final (table, keys) = _rpcTable[rpc]!;
    final stored = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      final key = [for (final k in keys) row[k]].join('|');
      final old = stored[key];
      if (old != null && (!row.containsKey('client_updated_at') || !_wins(table, row, old))) continue;
      stored[key] = {...row, 'updated_at': _now()};
    }
    await duringPush?.call();
  }

  static int _rank(Object? s) => switch (s) {
    'done' => 2,
    'in_progress' => 1,
    _ => 0,
  };

  static bool _wins(String table, Row a, Row b) {
    int at(Row r) => DateTime.parse(r['client_updated_at'] as String).microsecondsSinceEpoch;
    final List<num> x, y;
    switch (table) {
      case 'user_srs_cards':
        x = [a['reps'] as int, at(a)];
        y = [b['reps'] as int, at(b)];
      case 'user_lesson_progress':
        x = [_rank(a['status']), (a['score'] as num?) ?? -1, at(a)];
        y = [_rank(b['status']), (b['score'] as num?) ?? -1, at(b)];
      default:
        x = [at(a)];
        y = [at(b)];
    }
    for (var i = 0; i < x.length; i++) {
      if (x[i] != y[i]) return x[i] > y[i];
    }
    return false;
  }

  @override
  Future<List<Row>> pull(
    String table, {
    String? since,
    required List<String> order,
    int offset = 0,
    int limit = 1000,
  }) async {
    if (offline) throw Exception('SocketException: offline');
    DateTime t(Row r) => DateTime.parse(r['updated_at'] as String);
    final all = [
      for (final r in rows(table))
        if (since == null || t(r).isAfter(DateTime.parse(since))) r,
    ]..sort((a, b) => t(a).compareTo(t(b)));
    return all.skip(offset).take(limit).map((r) => {...r}).toList();
  }
}
