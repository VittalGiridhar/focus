import '../../../data/db/app_database.dart';
import '../domain/quiet_hours.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _onboardingKey = 'onboarding_complete';
  static const _goalKey = 'daily_goal_minutes';
  static const _quietEnabledKey = 'quiet_enabled';
  static const _quietStartKey = 'quiet_start';
  static const _quietEndKey = 'quiet_end';

  Future<String?> _get(String key) async {
    final row = await (_db.select(_db.settingsEntries)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _set(String key, String value) => _db.into(_db.settingsEntries).insertOnConflictUpdate(
        SettingsEntriesCompanion.insert(key: key, value: value),
      );

  Future<void> _remove(String key) =>
      (_db.delete(_db.settingsEntries)..where((t) => t.key.equals(key))).go();

  Future<bool> isOnboardingComplete() async => await _get(_onboardingKey) == 'true';

  Future<void> setOnboardingComplete(bool value) => _set(_onboardingKey, '$value');

  Future<Duration?> dailyGoal() async {
    final minutes = int.tryParse(await _get(_goalKey) ?? '');
    return minutes == null || minutes <= 0 ? null : Duration(minutes: minutes);
  }

  Future<void> setDailyGoal(Duration? goal) => goal == null
      ? _remove(_goalKey)
      : _set(_goalKey, '${goal.inMinutes.clamp(1, 24 * 60)}');

  Future<QuietHours> quietHours() async {
    final stored = QuietHours(
      enabled: await _get(_quietEnabledKey) == 'true',
      startMinute: int.tryParse(await _get(_quietStartKey) ?? '') ?? QuietHours.off.startMinute,
      endMinute: int.tryParse(await _get(_quietEndKey) ?? '') ?? QuietHours.off.endMinute,
    );
    // Corrupt or hand-edited values must not produce an unusable window.
    return stored.isValid ? stored : QuietHours.off;
  }

  Future<void> setQuietHours(QuietHours q) async {
    if (!q.isValid) throw ArgumentError('Quiet hours need different start and end times');
    await _db.transaction(() async {
      await _set(_quietEnabledKey, '${q.enabled}');
      await _set(_quietStartKey, '${q.startMinute}');
      await _set(_quietEndKey, '${q.endMinute}');
    });
  }
}
