import 'package:flutter/services.dart';

import '../features/limits/domain/usage_models.dart';
import '../features/modes/domain/mode.dart';
import '../features/settings/domain/quiet_hours.dart';
import 'usage_tracking_service.dart';

class AndroidUsageTrackingService implements UsageTrackingService {
  AndroidUsageTrackingService([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('com.focus.focus/usage');

  final MethodChannel _channel;

  @override
  Future<PermissionState> permissionState(EnforcementPermission permission) async {
    final method = switch (permission) {
      EnforcementPermission.usageAccess => 'usageAccessGranted',
      EnforcementPermission.accessibility => 'accessibilityEnabled',
      EnforcementPermission.notifications => 'notificationsGranted',
      EnforcementPermission.uninstallProtection => 'uninstallProtectionEnabled',
      _ => null,
    };
    if (method == null) return PermissionState.unsupported;
    final granted = await _channel.invokeMethod<bool>(method);
    return granted == true ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<void> openPermissionSettings(EnforcementPermission permission) async {
    final method = switch (permission) {
      EnforcementPermission.usageAccess => 'openUsageAccessSettings',
      EnforcementPermission.accessibility => 'openAccessibilitySettings',
      EnforcementPermission.uninstallProtection => 'requestUninstallProtection',
      _ => null,
    };
    if (method != null) await _channel.invokeMethod<void>(method);
  }

  @override
  Future<PermissionState> requestPermission(EnforcementPermission permission) async {
    if (permission != EnforcementPermission.notifications) {
      return permissionState(permission);
    }
    final granted = await _channel.invokeMethod<bool>('requestNotificationPermission');
    return granted == true ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<List<ActiveMode>> activeModes() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('activeModes');
    return [for (final m in raw ?? const <Map<Object?, Object?>>[]) _parseMode(m)];
  }

  @override
  Future<ActiveMode> startMode({
    required String id,
    required String name,
    required List<String> packageNames,
    required Duration duration,
  }) async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>('startMode', {
      'id': id,
      'name': name,
      'packages': packageNames,
      'durationMs': duration.inMilliseconds,
    });
    return _parseMode(raw!);
  }

  ActiveMode _parseMode(Map<Object?, Object?> m) => ActiveMode(
        id: m['id'] as String,
        name: m['name'] as String,
        packageNames: (m['packages'] as List<Object?>).cast<String>(),
        endsAt: DateTime.fromMillisecondsSinceEpoch((m['endsAtMs'] as num).toInt()),
      );

  @override
  Future<void> syncQuietHours(QuietHours quietHours) =>
      _channel.invokeMethod<void>('syncQuietHours', {
        'enabled': quietHours.enabled,
        'startMinute': quietHours.startMinute,
        'endMinute': quietHours.endMinute,
      });

  @override
  Future<void> eraseNativeData() => _channel.invokeMethod<void>('eraseAllData');

  @override
  Future<void> removeUninstallProtection() =>
      _channel.invokeMethod<void>('removeUninstallProtection');

  @override
  Future<ActiveMode> grantAccess({
    required String packageName,
    required String label,
    required Duration duration,
  }) async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>('grantAccess', {
      'packageName': packageName,
      'label': label,
      'durationMs': duration.inMilliseconds,
    });
    return _parseMode(raw!);
  }

  @override
  Future<List<ActiveMode>> activeGrants() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('activeGrants');
    return [for (final m in raw ?? const <Map<Object?, Object?>>[]) _parseMode(m)];
  }

  @override
  Future<void> removeFromBlocks(String packageName) =>
      _channel.invokeMethod<void>('removeFromBlocks', {'packageName': packageName});

  @override
  Future<void> setPartnerConfigured(bool configured) =>
      _channel.invokeMethod<void>('setPartnerConfigured', {'configured': configured});

  @override
  Future<InstalledApp?> takeUnlockRequest() async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>('takeUnlockRequest');
    if (raw == null) return null;
    return InstalledApp(packageName: raw['packageName'] as String, label: raw['label'] as String);
  }

  @override
  Future<bool> sendUnlockRequest({
    required String number,
    required String body,
    required bool whatsapp,
  }) async =>
      await _channel.invokeMethod<bool>('sendUnlockRequest', {
        'number': number,
        'body': body,
        'via': whatsapp ? 'whatsapp' : 'sms',
      }) ==
      true;

  @override
  Future<void> syncLimits(List<LimitRule> limits) =>
      _channel.invokeMethod<void>('syncLimits', {
        'limits': [
          for (final l in limits)
            {
              'packageName': l.appId,
              'label': l.label,
              'limitMinutes': l.dailyLimit.inMinutes,
              'enabled': l.enabled,
            },
        ],
      });

  @override
  Future<List<InstalledApp>> installedApps() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('installedApps');
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        InstalledApp(
          packageName: m['packageName'] as String,
          label: m['label'] as String,
        ),
    ];
  }

  @override
  Future<Uint8List?> appIcon(String packageName) =>
      _channel.invokeMethod<Uint8List>('appIcon', {'packageName': packageName});

  @override
  Future<List<UsageSession>> sessionsSince(DateTime since) async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('usageSessions', {
      'sinceMs': since.millisecondsSinceEpoch,
      'untilMs': DateTime.now().millisecondsSinceEpoch,
    });
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        UsageSession(
          appId: m['packageName'] as String,
          start: DateTime.fromMillisecondsSinceEpoch((m['startMs'] as num).toInt()),
          end: DateTime.fromMillisecondsSinceEpoch((m['endMs'] as num).toInt()),
        ),
    ];
  }
}
