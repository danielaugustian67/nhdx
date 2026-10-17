import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

import 'db_installer.dart';

CommonDatabase openReadOnly(String path) => throw UnsupportedError('No database files on the web');

int get sqliteVersionNumber => 3050000;

/// sqlite3.wasm from the sqlite3 package's release matching pubspec.lock.
Future<WasmSqlite3>? _sqlite;
Future<WasmSqlite3> _load() => _sqlite ??= WasmSqlite3.loadFromUrl(Uri.base.resolve('sqlite3.wasm'));

/// Each database keeps its own IndexedDB store: a store is read into memory
/// when opened, so the Korean dictionary costs nothing until it is used.
Future<(WasmSqlite3, IndexedDbFileSystem)> _store(String name) async {
  final sqlite = await _load();
  final fs = await IndexedDbFileSystem.open(dbName: 'nhdx-$name', vfsName: 'nhdx-$name');
  sqlite.registerVirtualFileSystem(fs);
  return (sqlite, fs);
}

final _opened = <String, Future<CommonDatabase>>{};

/// Opens the bundled read-only database [name]. Like [DbInstaller] on
/// native, it is unpacked into storage once per dataset version (sha256 in
/// `assets/db/manifest.json`) and opened from there on later launches.
///
/// The first open also installs the other databases in the background, so the
/// app keeps working offline (as an installed PWA) after one online launch.
Future<CommonDatabase> openBundled(String name) {
  final opening = _opened[name];
  if (opening != null) return opening;
  final future = _opened[name] = _openBundled(name);
  // A failed install (offline, say) is retried on the next open.
  future.then(
    (_) => _installRest(),
    onError: (Object _) {
      _opened.remove(name);
    },
  );
  return future;
}

var _installingRest = false;

void _installRest() {
  if (_installingRest) return;
  _installingRest = true;
  unawaited(() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    for (final name in (await _manifest()).keys) {
      try {
        await openBundled(name);
      } catch (_) {
        // Installed on first use instead.
      }
    }
  }());
}

Future<Map<String, dynamic>> _manifest() async =>
    jsonDecode(await rootBundle.loadString(DbInstaller.manifestAsset)) as Map<String, dynamic>;

Future<CommonDatabase> _openBundled(String name) async {
  final manifest = await _manifest();
  final entry = manifest[name] as Map<String, dynamic>?;
  if (entry == null) throw StateError('$name is not listed in ${DbInstaller.manifestAsset}');
  final sha = entry['sha256'] as String;

  final (sqlite, fs) = await _store(name);
  final path = '/$name';
  if (_readText(fs, '$path.sha256') != sha) {
    final data = await rootBundle.load(entry['asset'] as String);
    final bytes = await _gunzip(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    _writeFile(fs, path, bytes);
    _writeFile(fs, '$path.sha256', utf8.encode(sha));
    await fs.flush();
  }
  return sqlite.open(path, vfs: fs.name, mode: OpenMode.readOnly);
}

/// The read-write user.db, saved to IndexedDB after each write.
Future<QueryExecutor> openUserDb() async {
  final (sqlite, fs) = await _store('user.db');
  return WasmDatabase(sqlite3: sqlite, path: '/user.db', fileSystem: fs);
}

QueryExecutor memoryDatabase() => throw UnsupportedError('Tests run natively');

/// Unpacks with the browser's own gzip (Safari 16.4+). Some hosts serve
/// `.gz` files with `Content-Encoding: gzip`, so the browser may already
/// have unpacked them.
Future<Uint8List> _gunzip(Uint8List gz) async {
  if (gz.length < 2 || gz[0] != 0x1f || gz[1] != 0x8b) return gz;
  final stream = web.Blob([gz.toJS].toJS).stream().pipeThrough(
    web.DecompressionStream('gzip') as web.ReadableWritablePair,
  );
  final buffer = await web.Response(stream).arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

void _writeFile(VirtualFileSystem fs, String path, List<int> bytes) {
  final file = fs
      .xOpen(Sqlite3Filename(path), SqlFlag.SQLITE_OPEN_CREATE | SqlFlag.SQLITE_OPEN_READWRITE)
      .file;
  try {
    file.xTruncate(0);
    file.xWrite(bytes is Uint8List ? bytes : Uint8List.fromList(bytes), 0);
  } finally {
    file.xClose();
  }
}

String? _readText(VirtualFileSystem fs, String path) {
  if (fs.xAccess(path, 0) == 0) return null;
  final file = fs.xOpen(Sqlite3Filename(path), SqlFlag.SQLITE_OPEN_READONLY).file;
  try {
    final buffer = Uint8List(file.xFileSize());
    file.xRead(buffer, 0);
    return utf8.decode(buffer);
  } finally {
    file.xClose();
  }
}
