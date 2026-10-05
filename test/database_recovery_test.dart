import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus/data/db/database_recovery.dart';
import 'package:focus/features/settings/data/settings_repository.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('focus_db_test'));

  tearDown(() => dir.deleteSync(recursive: true));

  test('a healthy database opens without recovery and keeps its data', () async {
    final file = File('${dir.path}/focus.sqlite');
    var opened = await openDatabaseWithRecovery(file);
    expect(opened.recovered, isFalse);
    await SettingsRepository(opened.db).setOnboardingComplete(true);
    await opened.db.close();

    opened = await openDatabaseWithRecovery(file);
    expect(opened.recovered, isFalse);
    expect(await SettingsRepository(opened.db).isOnboardingComplete(), isTrue);
    await opened.db.close();
  });

  test('a corrupt file is kept aside and a fresh usable database is created', () async {
    final file = File('${dir.path}/focus.sqlite');
    file.writeAsBytesSync(List<int>.generate(4096, (i) => (i * 31 + 7) % 251));

    final opened = await openDatabaseWithRecovery(file);
    expect(opened.recovered, isTrue);

    final backups = dir.listSync().where((e) => e.path.contains('.corrupt-')).toList();
    expect(backups.length, 1);

    final settings = SettingsRepository(opened.db);
    expect(await settings.isOnboardingComplete(), isFalse);
    await settings.setOnboardingComplete(true);
    expect(await settings.isOnboardingComplete(), isTrue);
    await opened.db.close();
  });

  test('only the newest corrupt backup is kept', () async {
    final file = File('${dir.path}/focus.sqlite');
    File('${dir.path}/focus.sqlite.corrupt-1').writeAsStringSync('old');
    file.writeAsBytesSync(List<int>.generate(2048, (i) => (i * 17 + 3) % 249));

    final opened = await openDatabaseWithRecovery(file);
    await opened.db.close();

    final backups = dir.listSync().where((e) => e.path.contains('.corrupt-')).toList();
    expect(backups.length, 1);
    expect(backups.single.path.endsWith('corrupt-1'), isFalse);
  });
}
