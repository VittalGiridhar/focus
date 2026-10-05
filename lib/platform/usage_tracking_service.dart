import 'dart:typed_data';

import '../core/time/clock.dart';
import '../features/limits/domain/usage_models.dart';
import '../features/modes/domain/mode.dart';
import '../features/settings/domain/quiet_hours.dart';

enum PermissionState { granted, denied, notDetermined, unsupported }

enum EnforcementPermission {
  usageAccess,
  accessibility,
  notifications,
  exactAlarms,
  screenTime,
  uninstallProtection,
}

class InstalledApp {
  const InstalledApp({required this.packageName, required this.label});

  final String packageName;
  final String label;
}

abstract interface class UsageTrackingService {
  Future<PermissionState> permissionState(EnforcementPermission permission);

  /// Opens the system screen where [permission] is granted.
  Future<void> openPermissionSettings(EnforcementPermission permission);

  Future<List<InstalledApp>> installedApps();

  Future<Uint8List?> appIcon(String packageName);

  Future<List<UsageSession>> sessionsSince(DateTime since);

  /// Pushes the limits to the native layer, which enforces them even when the
  /// Flutter app is closed.
  Future<void> syncLimits(List<LimitRule> limits);

  /// Shows the system prompt where one exists (notifications). Returns the new state.
  Future<PermissionState> requestPermission(EnforcementPermission permission);

  /// Blocks that are running now (saved modes and quick blocks).
  Future<List<ActiveMode>> activeModes();

  /// Starts a block that keeps [packageNames] closed until [duration] has passed.
  /// There is deliberately no way to end it early.
  Future<ActiveMode> startMode({
    required String id,
    required String name,
    required List<String> packageNames,
    required Duration duration,
  });

  /// Pushes the quiet-hours window to the native layer, which enforces it.
  Future<void> syncQuietHours(QuietHours quietHours);

  /// Clears everything the native layer stores. Refused natively while locked.
  Future<void> eraseNativeData();

  /// Deactivates uninstall protection. Refused natively while locked.
  Future<void> removeUninstallProtection();

  /// A partner-approved break: [packageName] can be opened until [duration] passes.
  Future<ActiveMode> grantAccess({
    required String packageName,
    required String label,
    required Duration duration,
  });

  /// Breaks that are running now.
  Future<List<ActiveMode>> activeGrants();

  /// Takes [packageName] out of every running block (partner removed its block).
  Future<void> removeFromBlocks(String packageName);

  /// Lets the native block screen offer "Ask partner to unlock".
  Future<void> setPartnerConfigured(bool configured);

  /// An unlock request made from the native block screen, if one is waiting.
  Future<InstalledApp?> takeUnlockRequest();

  /// Opens the user's SMS or WhatsApp with [body] addressed to [number].
  /// Returns false when no suitable app is installed.
  Future<bool> sendUnlockRequest({
    required String number,
    required String body,
    required bool whatsapp,
  });
}

class SentRequest {
  const SentRequest(this.number, this.body, {required this.whatsapp});

  final String number;
  final String body;
  final bool whatsapp;
}

class FakeUsageTrackingService implements UsageTrackingService {
  FakeUsageTrackingService([Clock? clock]) : _clock = clock ?? const SystemClock();

  final Clock _clock;
  final Map<EnforcementPermission, PermissionState> permissions = {};
  final List<UsageSession> sessions = [];
  List<InstalledApp> apps = const [];
  List<ActiveMode> active = [];
  List<LimitRule> syncedLimits = const [];
  QuietHours syncedQuietHours = QuietHours.off;
  EnforcementPermission? lastSettingsOpened;
  int settingsOpened = 0;
  int permissionRequests = 0;
  PermissionState requestResult = PermissionState.granted;
  bool nativeErased = false;
  bool protectionRemoved = false;

  @override
  Future<PermissionState> permissionState(EnforcementPermission permission) async =>
      permissions[permission] ?? PermissionState.notDetermined;

  @override
  Future<void> openPermissionSettings(EnforcementPermission permission) async {
    settingsOpened++;
    lastSettingsOpened = permission;
  }

  @override
  Future<List<InstalledApp>> installedApps() async => apps;

  @override
  Future<Uint8List?> appIcon(String packageName) async => null;

  @override
  Future<List<UsageSession>> sessionsSince(DateTime since) async =>
      sessions.where((s) => s.end.isAfter(since)).toList();

  @override
  Future<void> syncLimits(List<LimitRule> limits) async => syncedLimits = limits;

  @override
  Future<PermissionState> requestPermission(EnforcementPermission permission) async {
    permissionRequests++;
    permissions[permission] = requestResult;
    return requestResult;
  }

  @override
  Future<List<ActiveMode>> activeModes() async =>
      [for (final m in active) if (m.endsAt.isAfter(_clock.now())) m];

  @override
  Future<ActiveMode> startMode({
    required String id,
    required String name,
    required List<String> packageNames,
    required Duration duration,
  }) async {
    final mode = ActiveMode(
      id: id,
      name: name,
      packageNames: packageNames,
      endsAt: _clock.now().add(duration),
    );
    active = [...active.where((m) => m.id != id), mode];
    return mode;
  }

  @override
  Future<void> syncQuietHours(QuietHours quietHours) async => syncedQuietHours = quietHours;

  @override
  Future<void> eraseNativeData() async {
    nativeErased = true;
    active = [];
    syncedLimits = const [];
    syncedQuietHours = QuietHours.off;
  }

  @override
  Future<void> removeUninstallProtection() async {
    protectionRemoved = true;
    permissions[EnforcementPermission.uninstallProtection] = PermissionState.denied;
  }

  List<ActiveMode> grants = [];
  final List<String> removedFromBlocks = [];
  final List<SentRequest> sentRequests = [];
  bool partnerConfigured = false;
  InstalledApp? pendingUnlock;

  @override
  Future<ActiveMode> grantAccess({
    required String packageName,
    required String label,
    required Duration duration,
  }) async {
    final grant = ActiveMode(
      id: 'grant-$packageName',
      name: label,
      packageNames: [packageName],
      endsAt: _clock.now().add(duration),
    );
    grants = [...grants.where((g) => g.id != grant.id), grant];
    return grant;
  }

  @override
  Future<List<ActiveMode>> activeGrants() async =>
      [for (final g in grants) if (g.endsAt.isAfter(_clock.now())) g];

  @override
  Future<void> removeFromBlocks(String packageName) async {
    removedFromBlocks.add(packageName);
    active = [
      for (final m in active)
        if (m.packageNames.any((p) => p != packageName))
          ActiveMode(
            id: m.id,
            name: m.name,
            packageNames: m.packageNames.where((p) => p != packageName).toList(),
            endsAt: m.endsAt,
          ),
    ];
  }

  @override
  Future<void> setPartnerConfigured(bool configured) async => partnerConfigured = configured;

  @override
  Future<InstalledApp?> takeUnlockRequest() async {
    final pending = pendingUnlock;
    pendingUnlock = null;
    return pending;
  }

  @override
  Future<bool> sendUnlockRequest({
    required String number,
    required String body,
    required bool whatsapp,
  }) async {
    sentRequests.add(SentRequest(number, body, whatsapp: whatsapp));
    return true;
  }
}
