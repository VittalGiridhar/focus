import 'package:drift/drift.dart';

import '../../../core/time/clock.dart';
import '../../../data/db/app_database.dart';
import '../domain/mode.dart';

class ModesRepository {
  ModesRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  static const maxNameLength = 40;
  static const maxDuration = Duration(hours: 24);

  Stream<List<FocusMode>> watchAll() {
    final query = _db.select(_db.modes)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().asyncMap((rows) async {
      final appRows = await (_db.select(_db.modeApps)
            ..orderBy([(t) => OrderingTerm.asc(t.label)]))
          .get();
      final byMode = <String, List<ModeApp>>{};
      for (final a in appRows) {
        byMode
            .putIfAbsent(a.modeId, () => [])
            .add(ModeApp(packageName: a.appId, label: a.label));
      }
      return [for (final r in rows) _fromRow(r, byMode[r.id] ?? const [])];
    });
  }

  Future<FocusMode> create({
    required String name,
    required Duration duration,
    List<ModeApp> apps = const [],
  }) async {
    final mode = FocusMode(
      id: _newId(),
      name: _validName(name),
      duration: _validDuration(duration),
      createdAt: _clock.now(),
      apps: apps,
    );
    await _db.transaction(() async {
      await _db.into(_db.modes).insert(ModesCompanion.insert(
            id: mode.id,
            name: mode.name,
            durationMinutes: mode.duration.inMinutes,
            createdAt: mode.createdAt,
          ));
      await _replaceApps(mode.id, mode.apps);
    });
    return mode;
  }

  Future<void> update(FocusMode mode) async {
    final name = _validName(mode.name);
    final duration = _validDuration(mode.duration);
    await _db.transaction(() async {
      await _replaceApps(mode.id, mode.apps);
      await (_db.update(_db.modes)..where((t) => t.id.equals(mode.id))).write(
        ModesCompanion(
          name: Value(name),
          durationMinutes: Value(duration.inMinutes),
        ),
      );
    });
  }

  Future<FocusMode> duplicate(FocusMode mode) {
    const suffix = ' copy';
    final base = mode.name.length + suffix.length > maxNameLength
        ? mode.name.substring(0, maxNameLength - suffix.length)
        : mode.name;
    return create(name: '$base$suffix', duration: mode.duration, apps: mode.apps);
  }

  Future<void> delete(String id) => _db.transaction(() async {
        await (_db.delete(_db.modeApps)..where((t) => t.modeId.equals(id))).go();
        await (_db.delete(_db.modes)..where((t) => t.id.equals(id))).go();
      });

  Future<void> _replaceApps(String modeId, List<ModeApp> apps) async {
    await (_db.delete(_db.modeApps)..where((t) => t.modeId.equals(modeId))).go();
    for (final a in apps) {
      await _db.into(_db.modeApps).insertOnConflictUpdate(ModeAppsCompanion.insert(
            modeId: modeId,
            appId: a.packageName,
            label: a.label,
          ));
    }
  }

  String _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxNameLength) {
      throw ArgumentError('Mode name must be 1-$maxNameLength characters');
    }
    return trimmed;
  }

  Duration _validDuration(Duration d) {
    if (d < const Duration(minutes: 1) || d > maxDuration) {
      throw ArgumentError('Mode duration must be between 1 minute and 24 hours');
    }
    return Duration(minutes: d.inMinutes);
  }

  String _newId() => '${_clock.now().microsecondsSinceEpoch}-${_counter++}';

  static int _counter = 0;

  FocusMode _fromRow(ModeRow row, List<ModeApp> apps) => FocusMode(
        id: row.id,
        name: row.name,
        duration: Duration(minutes: row.durationMinutes),
        createdAt: row.createdAt,
        apps: apps,
      );
}
