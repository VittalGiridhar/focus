import 'package:drift/drift.dart';

import '../../../data/db/app_database.dart';
import '../domain/partner.dart';

/// Stores the unlock partner in the app's private database.
class PartnerRepository {
  PartnerRepository(this._db);

  final AppDatabase _db;

  static const _prefix = 'partner_';
  static const _phone = '${_prefix}phone';
  static const _window = '${_prefix}window_minutes';
  static const _tempSecret = '${_prefix}temporary_secret';
  static const _removeSecret = '${_prefix}remove_secret';
  static const _tempCounter = '${_prefix}temporary_counter';
  static const _removeCounter = '${_prefix}remove_counter';
  static const _failures = '${_prefix}failures';
  static const _lockout = '${_prefix}lockout_until';

  Future<PartnerConfig?> load() async {
    final rows = await (_db.select(_db.settingsEntries)
          ..where((t) => t.key.like('$_prefix%')))
        .get();
    final v = {for (final r in rows) r.key: r.value};
    final phone = v[_phone];
    final temp = v[_tempSecret];
    final remove = v[_removeSecret];
    if (phone == null || temp == null || remove == null) return null;
    final lockout = int.tryParse(v[_lockout] ?? '');
    return PartnerConfig(
      phone: phone,
      unlockWindow: Duration(minutes: int.tryParse(v[_window] ?? '') ?? 15),
      temporarySecret: temp,
      removeSecret: remove,
      lastTemporaryCounter: int.tryParse(v[_tempCounter] ?? '') ?? -1,
      lastRemoveCounter: int.tryParse(v[_removeCounter] ?? '') ?? -1,
      failedAttempts: int.tryParse(v[_failures] ?? '') ?? 0,
      lockedOutUntil: lockout == null ? null : DateTime.fromMillisecondsSinceEpoch(lockout),
    );
  }

  Future<void> save(PartnerConfig c) => _db.transaction(() async {
        Future<void> put(String key, String value) => _db
            .into(_db.settingsEntries)
            .insertOnConflictUpdate(SettingsEntriesCompanion.insert(key: key, value: value));
        await put(_phone, c.phone);
        await put(_window, '${c.unlockWindow.inMinutes}');
        await put(_tempSecret, c.temporarySecret);
        await put(_removeSecret, c.removeSecret);
        await put(_tempCounter, '${c.lastTemporaryCounter}');
        await put(_removeCounter, '${c.lastRemoveCounter}');
        await put(_failures, '${c.failedAttempts}');
        if (c.lockedOutUntil == null) {
          await (_db.delete(_db.settingsEntries)..where((t) => t.key.equals(_lockout))).go();
        } else {
          await put(_lockout, '${c.lockedOutUntil!.millisecondsSinceEpoch}');
        }
      });

  Future<void> clear() =>
      (_db.delete(_db.settingsEntries)..where((t) => t.key.like('$_prefix%'))).go();
}
