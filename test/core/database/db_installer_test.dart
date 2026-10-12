import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/db_installer.dart';
import 'package:sqlite3/sqlite3.dart';

/// Serves assets from memory so the test does not depend on the 42 MB bundle.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);
  final Map<String, List<int>> files;

  @override
  Future<ByteData> load(String key) async {
    final bytes = files[key];
    if (bytes == null) throw StateError('missing asset $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

List<int> _gzDb(String marker) {
  final dir = Directory.systemTemp.createTempSync('src');
  final path = '${dir.path}/x.db';
  sqlite3.open(path)
    ..execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)')
    ..execute("INSERT INTO meta VALUES ('marker', ?)", [marker])
    ..close();
  final gz = gzip.encode(File(path).readAsBytesSync());
  dir.deleteSync(recursive: true);
  return gz;
}

Map<String, List<int>> _assets(String marker, String sha) => {
  DbInstaller.manifestAsset: utf8.encode(
    jsonEncode({
      'dictionary.db': {'asset': 'assets/db/dictionary.db.gz', 'sha256': sha},
    }),
  ),
  'assets/db/dictionary.db.gz': _gzDb(marker),
};

String _marker(String path) {
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  final value = db.select("SELECT value FROM meta WHERE key = 'marker'").first['value'] as String;
  db.close();
  return value;
}

void main() {
  late Directory target;
  setUp(() => target = Directory.systemTemp.createTempSync('nihondx_db'));
  tearDown(() => target.deleteSync(recursive: true));

  test('extracts on first launch and skips when unchanged', () async {
    final installer = DbInstaller(targetDir: target, bundle: _FakeBundle(_assets('v1', 'sha-1')));
    final path = await installer.ensureInstalled('dictionary.db');
    expect(_marker(path), 'v1');
    expect(File('$path.tmp').existsSync(), isFalse);

    final modified = File(path).lastModifiedSync();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await installer.ensureInstalled('dictionary.db');
    expect(File(path).lastModifiedSync(), modified);
  });

  test('replaces the database when the bundled sha changes', () async {
    await DbInstaller(targetDir: target, bundle: _FakeBundle(_assets('v1', 'sha-1'))).ensureInstalled('dictionary.db');

    String? replacedPath;
    final path = await DbInstaller(
      targetDir: target,
      bundle: _FakeBundle(_assets('v2', 'sha-2')),
    ).ensureInstalled('dictionary.db', onReplaced: (p) async => replacedPath = p);

    expect(_marker(path), 'v2');
    expect(replacedPath, path);
  });

  test('re-extracts after an interrupted install', () async {
    final installer = DbInstaller(targetDir: target, bundle: _FakeBundle(_assets('v1', 'sha-1')));
    final path = await installer.ensureInstalled('dictionary.db');
    File('$path.sha256').deleteSync(); // simulate a crash before the sha was recorded
    await installer.ensureInstalled('dictionary.db');
    expect(_marker(path), 'v1');
  });
}
