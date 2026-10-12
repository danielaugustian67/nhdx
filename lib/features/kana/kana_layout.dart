import '../../core/database/content_db.dart';

/// Arranges kana into the gojūon table (ui-design §5.7): 5 vowel columns for
/// basic/dakuten (with gaps in the ya and wa rows), 3 columns (ya/yu/yo) for
/// yōon. Rows keep the database order.
List<List<Kana?>> gojuonRows(List<Kana> kana) {
  if (kana.isEmpty) return const [];
  final yoon = kana.first.isYoon;
  final columns = yoon ? 3 : 5;
  final rows = <String, List<Kana?>>{};
  for (final k in kana) {
    final row = rows.putIfAbsent(k.rowGroup, () => List<Kana?>.filled(columns, null));
    row[_column(k, yoon)] = k;
  }
  return rows.values.toList();
}

int _column(Kana k, bool yoon) {
  if (k.romaji == 'n') return 0;
  final vowel = k.romaji[k.romaji.length - 1];
  return yoon ? const {'a': 0, 'u': 1, 'o': 2}[vowel]! : 'aiueo'.indexOf(vowel);
}
