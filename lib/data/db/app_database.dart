import 'package:drift/drift.dart';

part 'app_database.g.dart';

class SettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('ModeRow')
class Modes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LimitRow')
class LimitRules extends Table {
  TextColumn get appId => text()();
  TextColumn get label => text()();
  IntColumn get dailyLimitMinutes => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {appId};
}

@DataClassName('ModeAppRow')
class ModeApps extends Table {
  TextColumn get modeId => text()();
  TextColumn get appId => text()();
  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {modeId, appId};
}

@DriftDatabase(tables: [SettingsEntries, Modes, LimitRules, ModeApps])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(limitRules);
          if (from < 3) await m.createTable(modeApps);
        },
      );

  /// Removes everything the user has stored (privacy "delete my data").
  Future<void> eraseAll() => transaction(() async {
        for (final table in allTables) {
          await delete(table).go();
        }
      });
}
