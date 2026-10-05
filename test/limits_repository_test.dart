import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/data/db/app_database.dart';
import 'package:focus/features/limits/data/limits_repository.dart';
import 'package:focus/features/limits/domain/usage_models.dart';

void main() {
  late AppDatabase db;
  late LimitsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LimitsRepository(db);
  });

  tearDown(() => db.close());

  test('upsert replaces an existing limit for the same app', () async {
    await repo.upsert(LimitRule(
        appId: 'com.a', label: 'Alpha', dailyLimit: const Duration(minutes: 30)));
    await repo.upsert(LimitRule(
        appId: 'com.a', label: 'Alpha', dailyLimit: const Duration(hours: 2)));
    final all = await repo.watchAll().first;
    expect(all.single.dailyLimit, const Duration(hours: 2));
  });

  test('lists limits ordered by label and deletes by app', () async {
    await repo.upsert(LimitRule(
        appId: 'com.b', label: 'Beta', dailyLimit: const Duration(minutes: 20)));
    await repo.upsert(LimitRule(
        appId: 'com.a', label: 'Alpha', dailyLimit: const Duration(minutes: 20)));
    expect((await repo.watchAll().first).map((r) => r.label), ['Alpha', 'Beta']);
    await repo.delete('com.a');
    expect((await repo.watchAll().first).single.appId, 'com.b');
  });

  test('accepts the 12 hour maximum', () async {
    await repo.upsert(LimitRule(
        appId: 'com.a', label: 'Alpha', dailyLimit: const Duration(hours: 12)));
    expect((await repo.watchAll().first).single.dailyLimit, const Duration(hours: 12));
  });

  test('migrating a v1 database to v2 keeps data and adds limits table', () async {
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE settings_entries (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
      raw.execute(
          'CREATE TABLE modes (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, duration_minutes INTEGER NOT NULL, created_at INTEGER NOT NULL)');
      raw.execute("INSERT INTO modes VALUES ('m1', 'Deep Work', 120, 1700000000)");
      raw.execute("INSERT INTO settings_entries VALUES ('onboarding_complete', 'true')");
      raw.execute('PRAGMA user_version = 1');
    });
    final migrated = AppDatabase(executor);
    addTearDown(migrated.close);

    final modes = await migrated.select(migrated.modes).get();
    expect(modes.single.name, 'Deep Work');
    expect(modes.single.durationMinutes, 120);

    await LimitsRepository(migrated).upsert(LimitRule(
        appId: 'com.a', label: 'Alpha', dailyLimit: const Duration(minutes: 45)));
    expect((await LimitsRepository(migrated).watchAll().first).length, 1);

    final settings = await migrated.select(migrated.settingsEntries).get();
    expect(settings.single.value, 'true');
  });

  test('a limit above 12 hours cannot be constructed', () {
    expect(
      () => LimitRule(appId: 'com.a', label: 'Alpha', dailyLimit: const Duration(hours: 13)),
      throwsA(isA<AssertionError>()),
    );
  });
}
