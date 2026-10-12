import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Installs the bundled read-only databases (PRD §6, "Siklus hidup database
/// lokal").
///
/// `assets/db/manifest.json` (written by `data_pipeline/scripts/export_assets.py`)
/// lists each `*.db.gz` with its sha256. A database is (re-)extracted when it
/// is missing or its recorded sha256 differs from the manifest, i.e. after an
/// app update that ships a new dataset. Extraction streams the gzip into a
/// temporary file on a background isolate and renames it into place, so an
/// interrupted install is simply retried on the next launch.
class DbInstaller {
  DbInstaller({required this.targetDir, AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final Directory targetDir;
  final AssetBundle _bundle;

  static const manifestAsset = 'assets/db/manifest.json';

  /// Returns the installed file path. [onReplaced] runs after an existing
  /// database was replaced by a different version (hook for ID remapping in
  /// user.db, PRD §7).
  Future<String> ensureInstalled(String name, {Future<void> Function(String path)? onReplaced}) async {
    final manifest = jsonDecode(await _bundle.loadString(manifestAsset)) as Map<String, dynamic>;
    final entry = manifest[name] as Map<String, dynamic>?;
    if (entry == null) throw StateError('$name is not listed in $manifestAsset');

    final expectedSha = entry['sha256'] as String;
    final dbFile = File(p.join(targetDir.path, name));
    final shaFile = File('${dbFile.path}.sha256');

    if (dbFile.existsSync() && shaFile.existsSync() && shaFile.readAsStringSync().trim() == expectedSha) {
      return dbFile.path;
    }
    final replacing = dbFile.existsSync();

    targetDir.createSync(recursive: true);
    final data = await _bundle.load(entry['asset'] as String);
    final transferable = TransferableTypedData.fromList([
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    ]);
    await Isolate.run(() => _extract(transferable, dbFile.path));
    shaFile.writeAsStringSync(expectedSha);

    if (replacing && onReplaced != null) await onReplaced(dbFile.path);
    return dbFile.path;
  }

  static void _extract(TransferableTypedData gz, String target) {
    final bytes = gz.materialize().asUint8List();
    final tmp = File('$target.tmp');
    final sink = tmp.openSync(mode: FileMode.writeOnly);
    try {
      final output = _RandomAccessSink(sink);
      final decoder = gzip.decoder.startChunkedConversion(output);
      const chunk = 1 << 20;
      for (var offset = 0; offset < bytes.length; offset += chunk) {
        final end = offset + chunk < bytes.length ? offset + chunk : bytes.length;
        decoder.add(Uint8List.sublistView(bytes, offset, end));
      }
      decoder.close();
    } finally {
      sink.closeSync();
    }
    // Remove stale rollback journals of the previous file before swapping.
    for (final suffix in ['-journal', '-wal', '-shm']) {
      final f = File('$target$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    tmp.renameSync(target);
  }
}

class _RandomAccessSink implements Sink<List<int>> {
  _RandomAccessSink(this._file);
  final RandomAccessFile _file;

  @override
  void add(List<int> data) => _file.writeFromSync(data);

  @override
  void close() => _file.flushSync();
}
