import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'db_installer.dart';

/// Opens a database file read-only.
CommonDatabase openReadOnly(String path) => sqlite3.open(path, mode: OpenMode.readOnly);

/// Version of the SQLite library in use, e.g. 3045001.
int get sqliteVersionNumber => sqlite3.version.versionNumber;

Future<DbInstaller>? _installer;

/// Installs (first launch / after an app update) and opens the bundled
/// read-only database [name], e.g. `content.db`.
Future<CommonDatabase> openBundled(String name) async {
  final installer = await (_installer ??= getApplicationSupportDirectory().then(
    (support) => DbInstaller(targetDir: Directory(p.join(support.path, 'db'))),
  ));
  return openReadOnly(await installer.ensureInstalled(name));
}

/// The read-write user.db.
Future<QueryExecutor> openUserDb() async {
  final support = await getApplicationSupportDirectory();
  return NativeDatabase.createInBackground(File(p.join(support.path, 'user.db')));
}

QueryExecutor memoryDatabase() => NativeDatabase.memory();
