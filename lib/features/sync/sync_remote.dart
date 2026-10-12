import 'package:supabase_flutter/supabase_flutter.dart';

typedef Row = Map<String, dynamic>;

/// The cloud side of sync (PRD §8): push RPCs that apply the conflict rules
/// on the server, and paged reads of the account's rows.
abstract class SyncRemote {
  /// Sends [rows] to the push RPC [rpc].
  Future<void> push(String rpc, List<Row> rows);

  /// The account's rows of [table] changed after [since] (all when null), in
  /// server `updated_at` order, [limit] from [offset]. [order] breaks ties.
  Future<List<Row>> pull(String table, {String? since, required List<String> order, int offset, int limit});
}

class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);
  final SupabaseClient _client;

  @override
  Future<void> push(String rpc, List<Row> rows) => _client.rpc<dynamic>(rpc, params: {'rows': rows});

  @override
  Future<List<Row>> pull(
    String table, {
    String? since,
    required List<String> order,
    int offset = 0,
    int limit = 1000,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not signed in');
    // RLS limits reads to the account already; the filter uses the index.
    var query = _client.from(table).select().eq('user_id', user.id);
    if (since != null) query = query.gt('updated_at', since);
    var ordered = query.order('updated_at', ascending: true);
    for (final column in order) {
      ordered = ordered.order(column, ascending: true);
    }
    return ordered.range(offset, offset + limit - 1);
  }
}
