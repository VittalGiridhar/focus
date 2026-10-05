import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/time/clock.dart';
import 'package:focus/data/db/app_database.dart';
import 'package:focus/features/modes/data/modes_repository.dart';
import 'package:focus/features/modes/domain/mode.dart';
import 'package:focus/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase db;
  late ModesRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ModesRepository(db, FixedClock(DateTime(2026, 3, 10, 9)));
  });

  tearDown(() => db.close());

  test('create, list, update, duplicate, delete', () async {
    final m = await repo.create(name: '  Deep Work ', duration: const Duration(hours: 2));
    expect(m.name, 'Deep Work');

    var all = await repo.watchAll().first;
    expect(all.single.duration, const Duration(hours: 2));

    await repo.update(m.copyWith(name: 'Study', duration: const Duration(minutes: 90)));
    all = await repo.watchAll().first;
    expect(all.single.name, 'Study');
    expect(all.single.duration, const Duration(minutes: 90));

    final copy = await repo.duplicate(all.single);
    expect(copy.name, 'Study copy');
    expect((await repo.watchAll().first).length, 2);

    await repo.delete(m.id);
    expect((await repo.watchAll().first).single.id, copy.id);
  });

  test('rejects invalid names and durations', () async {
    expect(() => repo.create(name: '   ', duration: const Duration(hours: 1)),
        throwsArgumentError);
    expect(() => repo.create(name: 'x' * 41, duration: const Duration(hours: 1)),
        throwsArgumentError);
    expect(() => repo.create(name: 'Ok', duration: Duration.zero), throwsArgumentError);
    expect(() => repo.create(name: 'Ok', duration: const Duration(hours: 25)),
        throwsArgumentError);
  });

  test('duplicate of a max-length name still fits the limit', () async {
    final m = await repo.create(name: 'x' * 40, duration: const Duration(hours: 1));
    final copy = await repo.duplicate(m);
    expect(copy.name.length, lessThanOrEqualTo(ModesRepository.maxNameLength));
  });

  test('apps are stored with a mode, replaced on update, copied on duplicate, removed on delete',
      () async {
    const a = ModeApp(packageName: 'com.a', label: 'Alpha');
    const b = ModeApp(packageName: 'com.b', label: 'Beta');
    final m = await repo.create(
      name: 'Deep Work',
      duration: const Duration(hours: 1),
      apps: const [b, a],
    );
    var all = await repo.watchAll().first;
    expect(all.single.apps, [a, b]);

    await repo.update(m.copyWith(apps: const [b]));
    all = await repo.watchAll().first;
    expect(all.single.apps, [b]);

    final copy = await repo.duplicate(all.single);
    all = await repo.watchAll().first;
    expect(all.firstWhere((x) => x.id == copy.id).apps, [b]);

    await repo.delete(m.id);
    await repo.delete(copy.id);
    expect(await db.select(db.modeApps).get(), isEmpty);
  });

  test('migrating a v2 database to v3 keeps limits and adds mode apps', () async {
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE settings_entries (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
      raw.execute(
          'CREATE TABLE modes (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, duration_minutes INTEGER NOT NULL, created_at INTEGER NOT NULL)');
      raw.execute(
          'CREATE TABLE limit_rules (app_id TEXT NOT NULL PRIMARY KEY, label TEXT NOT NULL, daily_limit_minutes INTEGER NOT NULL, enabled INTEGER NOT NULL DEFAULT 1)');
      raw.execute("INSERT INTO modes VALUES ('m1', 'Deep Work', 120, 1700000000)");
      raw.execute("INSERT INTO limit_rules VALUES ('com.a', 'Alpha', 45, 1)");
      raw.execute('PRAGMA user_version = 2');
    });
    final migrated = AppDatabase(executor);
    addTearDown(migrated.close);

    final limits = await migrated.select(migrated.limitRules).get();
    expect(limits.single.dailyLimitMinutes, 45);

    final migratedRepo = ModesRepository(migrated, FixedClock(DateTime(2026, 3, 10)));
    final modes = await migratedRepo.watchAll().first;
    expect(modes.single.name, 'Deep Work');
    expect(modes.single.apps, isEmpty);

    await migratedRepo.update(
        modes.single.copyWith(apps: const [ModeApp(packageName: 'com.a', label: 'Alpha')]));
    expect((await migratedRepo.watchAll().first).single.apps.length, 1);
  });

  test('onboarding flag persists', () async {
    final settings = SettingsRepository(db);
    expect(await settings.isOnboardingComplete(), isFalse);
    await settings.setOnboardingComplete(true);
    expect(await settings.isOnboardingComplete(), isTrue);
  });
}
