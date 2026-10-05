import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time/clock.dart';
import '../data/db/app_database.dart';
import '../features/insights/domain/usage_aggregator.dart';
import '../features/limits/data/limits_repository.dart';
import '../features/limits/domain/lock_policy.dart';
import '../features/limits/domain/usage_calculator.dart';
import '../features/limits/domain/usage_models.dart';
import '../features/modes/data/modes_repository.dart';
import '../features/modes/domain/mode.dart';
import '../features/partner/data/partner_repository.dart';
import '../features/partner/domain/partner.dart';
import '../features/partner/domain/totp.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/settings/domain/quiet_hours.dart';
import '../platform/android_usage_tracking_service.dart';
import '../platform/usage_tracking_service.dart';

/// Always overridden at startup (and in tests) with an opened database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// True when the saved data was unreadable and the app started fresh.
final databaseRecoveredProvider = Provider<bool>((ref) => false);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

final modesRepositoryProvider = Provider(
  (ref) => ModesRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final modesProvider = StreamProvider<List<FocusMode>>(
  (ref) => ref.watch(modesRepositoryProvider).watchAll(),
);

final limitsRepositoryProvider =
    Provider((ref) => LimitsRepository(ref.watch(databaseProvider)));

final limitsProvider = StreamProvider<List<LimitRule>>(
  (ref) => ref.watch(limitsRepositoryProvider).watchAll(),
);

final usageServiceProvider = Provider<UsageTrackingService>(
  (ref) => Platform.isAndroid ? AndroidUsageTrackingService() : FakeUsageTrackingService(),
);

final usageAccessProvider = FutureProvider.autoDispose<PermissionState>(
  (ref) => ref
      .watch(usageServiceProvider)
      .permissionState(EnforcementPermission.usageAccess),
);

final accessibilityProvider = FutureProvider.autoDispose<PermissionState>(
  (ref) => ref
      .watch(usageServiceProvider)
      .permissionState(EnforcementPermission.accessibility),
);

/// Keeps the native enforcement layer's copy of the limits up to date.
final limitsSyncProvider = Provider<void>((ref) {
  final service = ref.watch(usageServiceProvider);
  ref.listen<AsyncValue<List<LimitRule>>>(limitsProvider, (_, next) {
    final limits = next.valueOrNull;
    if (limits != null) {
      service.syncLimits(limits).catchError((Object e) => debugPrint('syncLimits failed: $e'));
    }
  }, fireImmediately: true);
});

final activeModesProvider = FutureProvider.autoDispose<List<ActiveMode>>(
  (ref) => ref.watch(usageServiceProvider).activeModes(),
);

final uninstallProtectionProvider = FutureProvider.autoDispose<PermissionState>(
  (ref) => ref
      .watch(usageServiceProvider)
      .permissionState(EnforcementPermission.uninstallProtection),
);

/// What is locked right now. While anything is locked the app refuses changes that
/// would let the user open a blocked app again.
final lockStateProvider = Provider.autoDispose<CommitmentLock>((ref) {
  final clock = ref.watch(clockProvider);
  final now = ref.watch(clockTickProvider).valueOrNull ?? clock.now();
  final limits = ref.watch(limitsProvider).valueOrNull ?? const [];
  final usage = ref.watch(todayUsageProvider).valueOrNull ?? const [];
  final blocks = ref.watch(activeModesProvider).valueOrNull ?? const [];
  final quiet = ref.watch(quietHoursProvider).valueOrNull ?? QuietHours.off;
  const calc = UsageCalculator();
  return const LockPolicy().compute(
    now: now,
    limits: limits,
    statuses: {for (final u in usage) u.rule.appId: u.status},
    blocks: blocks,
    quiet: quiet,
    nextDayStart: calc.nextDayStart,
  );
});

/// Emits once a second so countdowns repaint; tests override it with a fixed value.
final clockTickProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) => clock.now());
});

final installedAppsProvider = FutureProvider.autoDispose<List<InstalledApp>>(
  (ref) => ref.watch(usageServiceProvider).installedApps(),
);

final appIconProvider = FutureProvider.family<Uint8List?, String>(
  (ref, packageName) => ref.watch(usageServiceProvider).appIcon(packageName),
);

class AppUsage {
  const AppUsage({required this.rule, required this.status});

  final LimitRule rule;
  final UsageStatus status;
}

/// Today's usage for every limited app. Empty when usage access is missing.
final todayUsageProvider = FutureProvider.autoDispose<List<AppUsage>>((ref) async {
  final limits = await ref.watch(limitsProvider.future);
  if (limits.isEmpty) return const [];
  final service = ref.watch(usageServiceProvider);
  final access = await service.permissionState(EnforcementPermission.usageAccess);
  if (access != PermissionState.granted) return const [];

  const calc = UsageCalculator();
  final now = ref.read(clockProvider).now();
  final sessions = await service.sessionsSince(calc.dayStart(now));
  return [
    for (final rule in limits)
      AppUsage(rule: rule, status: calc.statusFor(rule, sessions, now)),
  ];
});

class QuietHoursNotifier extends AsyncNotifier<QuietHours> {
  @override
  Future<QuietHours> build() => ref.watch(settingsRepositoryProvider).quietHours();

  Future<void> save(QuietHours quietHours) async {
    await ref.read(settingsRepositoryProvider).setQuietHours(quietHours);
    state = AsyncData(quietHours);
  }
}

final quietHoursProvider =
    AsyncNotifierProvider<QuietHoursNotifier, QuietHours>(QuietHoursNotifier.new);

/// Keeps the native copy of the quiet hours up to date.
final quietHoursSyncProvider = Provider<void>((ref) {
  final service = ref.watch(usageServiceProvider);
  ref.listen<AsyncValue<QuietHours>>(quietHoursProvider, (_, next) {
    final q = next.valueOrNull;
    if (q != null) {
      service.syncQuietHours(q).catchError((Object e) => debugPrint('syncQuietHours failed: $e'));
    }
  }, fireImmediately: true);
});

class DailyGoalNotifier extends AsyncNotifier<Duration?> {
  @override
  Future<Duration?> build() => ref.watch(settingsRepositoryProvider).dailyGoal();

  Future<void> save(Duration? goal) async {
    await ref.read(settingsRepositoryProvider).setDailyGoal(goal);
    state = AsyncData(goal);
  }
}

final dailyGoalProvider = AsyncNotifierProvider<DailyGoalNotifier, Duration?>(DailyGoalNotifier.new);

/// Last seven days of screen time for launchable apps (calls and system UI excluded).
final weeklyUsageProvider = FutureProvider.autoDispose<WeeklyUsage?>((ref) async {
  final service = ref.watch(usageServiceProvider);
  final access = await service.permissionState(EnforcementPermission.usageAccess);
  if (access != PermissionState.granted) return null;
  final apps = await ref.watch(installedAppsProvider.future);
  final now = ref.read(clockProvider).now();
  final since = DateTime(now.year, now.month, now.day - 6);
  final sessions = await service.sessionsSince(since);
  return const UsageAggregator().weekly(
    sessions,
    now,
    labels: {for (final a in apps) a.packageName: a.label},
  );
});

/// Deletes everything stored on this device and returns the app to first launch.
Future<void> eraseAllData(WidgetRef ref) async {
  await ref.read(usageServiceProvider).eraseNativeData();
  await ref.read(databaseProvider).eraseAll();
  ref.invalidate(quietHoursProvider);
  ref.invalidate(dailyGoalProvider);
  ref.invalidate(activeModesProvider);
  await ref.read(onboardingCompleteProvider.notifier).set(false);
}

final partnerRepositoryProvider =
    Provider((ref) => PartnerRepository(ref.watch(databaseProvider)));

/// Source of new authenticator secrets; tests override it to get predictable codes.
final secretGeneratorProvider = Provider<Uint8List Function()>((ref) => () => Totp.newSecret());

class PartnerNotifier extends AsyncNotifier<PartnerConfig?> {
  @override
  Future<PartnerConfig?> build() => ref.watch(partnerRepositoryProvider).load();

  Future<void> save(PartnerConfig config) async {
    await ref.read(partnerRepositoryProvider).save(config);
    state = AsyncData(config);
  }

  Future<void> clear() async {
    await ref.read(partnerRepositoryProvider).clear();
    state = const AsyncData(null);
  }

  /// Checks a code from the partner and records the attempt. Null when no partner is set.
  Future<VerifyOutcome?> verify(String code, {bool removeOnly = false}) async {
    final config = await future;
    if (config == null) return null;
    final outcome = const PartnerVerifier()
        .verify(config, code, ref.read(clockProvider).now(), removeOnly: removeOnly);
    await ref.read(partnerRepositoryProvider).save(outcome.config);
    state = AsyncData(outcome.config);
    return outcome;
  }
}

final partnerProvider =
    AsyncNotifierProvider<PartnerNotifier, PartnerConfig?>(PartnerNotifier.new);

/// Tells the native block screen whether "Ask partner to unlock" can be offered.
final partnerSyncProvider = Provider<void>((ref) {
  final service = ref.watch(usageServiceProvider);
  ref.listen<AsyncValue<PartnerConfig?>>(partnerProvider, (_, next) {
    if (next.hasValue) {
      service
          .setPartnerConfigured(next.value != null)
          .catchError((Object e) => debugPrint('setPartnerConfigured failed: $e'));
    }
  }, fireImmediately: true);
});

final activeGrantsProvider = FutureProvider.autoDispose<List<ActiveMode>>(
  (ref) => ref.watch(usageServiceProvider).activeGrants(),
);

/// Overridden at startup with the persisted value so routing needs no loading state.
final initialOnboardingCompleteProvider = Provider<bool>((ref) => false);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialOnboardingCompleteProvider);

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setOnboardingComplete(value);
    state = value;
  }
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
