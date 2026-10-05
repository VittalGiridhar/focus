import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

class OpenedDatabase {
  const OpenedDatabase(this.db, {required this.recovered});

  final AppDatabase db;

  /// True when the stored data could not be read and a fresh database was created.
  final bool recovered;
}

/// Opens the database at [file]. If it cannot be read (for example the file is
/// corrupted), the unreadable file is kept aside as a single backup and a fresh
/// database is created, so the app starts instead of crashing.
Future<OpenedDatabase> openDatabaseWithRecovery(File file) async {
  AppDatabase open() => AppDatabase(NativeDatabase.createInBackground(file));

  var db = open();
  try {
    await db.customSelect('SELECT 1').get(); // forces open and migrations
    return OpenedDatabase(db, recovered: false);
  } catch (e) {
    debugPrint('Database could not be opened, starting fresh: ${e.runtimeType}');
    try {
      await db.close();
    } catch (_) {}
    await _moveAside(file);
    db = open();
    await db.customSelect('SELECT 1').get();
    return OpenedDatabase(db, recovered: true);
  }
}

Future<void> _moveAside(File file) async {
  final dir = file.parent;
  final name = file.uri.pathSegments.last;
  // Keep only the newest unreadable backup rather than accumulating user data.
  await for (final entity in dir.list()) {
    final base = entity.uri.pathSegments.last;
    if (entity is File && base.startsWith('$name.corrupt-')) {
      await entity.delete();
    }
  }
  if (await file.exists()) {
    await file.rename('${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}');
  }
  for (final suffix in ['-wal', '-shm', '-journal']) {
    final sidecar = File('${file.path}$suffix');
    if (await sidecar.exists()) await sidecar.delete();
  }
}
