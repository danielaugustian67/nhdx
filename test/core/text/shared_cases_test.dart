import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/text/normalize.dart';

/// Runs data_pipeline/shared_test_cases/*.json against the Dart side so the
/// app normalizes queries exactly like the pipeline normalized the index.
void main() {
  final functions = <String, String Function(String)>{
    'normalize_jp': normalizeJp,
    'normalize_latin': normalizeLatin,
    'romaji_search': romajiSearch,
  };
  const notInApp = {
    'kana_to_romaji': 'pipeline only (romaji is precomputed in dictionary.db)',
    // Dictionary meanings are English only (prd.md §F1.2, Oct 2026), so the
    // app never stems Indonesian queries.
    'stem_id': 'pipeline only (meanings are English only; no Dart stemmer)',
  };

  final dir = Directory('data_pipeline/shared_test_cases');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('shared case files exist', () => expect(files, isNotEmpty));

  for (final file in files) {
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    for (final entry in data.entries.where((e) => !e.key.startsWith('_'))) {
      final fn = functions[entry.key];
      group('${file.uri.pathSegments.last} ${entry.key}', () {
        for (final pair in (entry.value as List).cast<List>()) {
          final given = pair[0] as String;
          final expected = pair[1] as String;
          test(
            '"$given" → "$expected"',
            () => expect(fn!(given), expected),
            skip: fn == null ? notInApp[entry.key] ?? 'no Dart implementation' : false,
          );
        }
      });
    }
  }
}
