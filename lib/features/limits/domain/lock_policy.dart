import 'package:equatable/equatable.dart';

import '../../modes/domain/mode.dart';
import '../../settings/domain/quiet_hours.dart';
import 'usage_models.dart';

/// What is currently locked, and until when. While something is locked the user
/// cannot weaken the commitment from inside the app (remove or loosen a limit,
/// edit a running mode, switch off quiet hours, or delete their data).
class CommitmentLock extends Equatable {
  const CommitmentLock({
    this.lockedApps = const {},
    this.runningModeIds = const {},
    this.quietUntil,
    this.blocksUntil,
  });

  static const none = CommitmentLock();

  final Map<String, DateTime> lockedApps;
  final Set<String> runningModeIds;
  final DateTime? quietUntil;
  final DateTime? blocksUntil;

  bool isAppLocked(String packageName) => lockedApps.containsKey(packageName);

  DateTime? appLockedUntil(String packageName) => lockedApps[packageName];

  bool isModeRunning(String modeId) => runningModeIds.contains(modeId);

  bool get isQuietActive => quietUntil != null;

  /// True while anything at all is locked.
  bool get anyLock => anyLockUntil != null;

  /// When the longest lock ends.
  DateTime? get anyLockUntil {
    DateTime? latest;
    void consider(DateTime? t) {
      if (t != null && (latest == null || t.isAfter(latest!))) latest = t;
    }

    lockedApps.values.forEach(consider);
    consider(quietUntil);
    consider(blocksUntil);
    return latest;
  }

  @override
  List<Object?> get props => [lockedApps, runningModeIds, quietUntil, blocksUntil];
}

class LockPolicy {
  const LockPolicy();

  CommitmentLock compute({
    required DateTime now,
    required List<LimitRule> limits,
    required Map<String, UsageStatus> statuses,
    required List<ActiveMode> blocks,
    required QuietHours quiet,
    required DateTime Function(DateTime) nextDayStart,
  }) {
    final locked = <String, DateTime>{};
    void lock(String pkg, DateTime until) {
      final current = locked[pkg];
      if (current == null || until.isAfter(current)) locked[pkg] = until;
    }

    // A limited app that has used up its allowance stays locked until the day resets.
    final reset = nextDayStart(now);
    for (final rule in limits) {
      if (!rule.enabled) continue;
      final status = statuses[rule.appId];
      if (status != null && status.isLimitReached) lock(rule.appId, reset);
    }

    DateTime? blocksUntil;
    final running = <String>{};
    for (final block in blocks) {
      if (!block.endsAt.isAfter(now)) continue;
      running.add(block.id);
      for (final pkg in block.packageNames) {
        lock(pkg, block.endsAt);
      }
      if (blocksUntil == null || block.endsAt.isAfter(blocksUntil)) blocksUntil = block.endsAt;
    }

    DateTime? quietUntil;
    if (quiet.isActiveAt(now)) {
      final end = quietEnd(now, quiet);
      final enabledLimits = limits.where((r) => r.enabled);
      if (enabledLimits.isNotEmpty) {
        quietUntil = end;
        for (final rule in enabledLimits) {
          lock(rule.appId, end);
        }
      }
    }

    return CommitmentLock(
      lockedApps: locked,
      runningModeIds: running,
      quietUntil: quietUntil,
      blocksUntil: blocksUntil,
    );
  }

  /// The next time the quiet window ends after [now].
  DateTime quietEnd(DateTime now, QuietHours quiet) {
    var end = DateTime(now.year, now.month, now.day, quiet.endMinute ~/ 60, quiet.endMinute % 60);
    if (!end.isAfter(now)) {
      end = DateTime(now.year, now.month, now.day + 1, quiet.endMinute ~/ 60, quiet.endMinute % 60);
    }
    return end;
  }
}
