import 'package:flutter_test/flutter_test.dart';
import 'package:focus/features/limits/domain/lock_policy.dart';
import 'package:focus/features/limits/domain/usage_calculator.dart';
import 'package:focus/features/limits/domain/usage_models.dart';
import 'package:focus/features/modes/domain/mode.dart';
import 'package:focus/features/settings/domain/quiet_hours.dart';

void main() {
  const policy = LockPolicy();
  const calc = UsageCalculator();
  final noon = DateTime(2026, 3, 10, 12);

  LimitRule rule(String app, int minutes) =>
      LimitRule(appId: app, label: app, dailyLimit: Duration(minutes: minutes));

  UsageStatus status(String app, int used, int limit) => UsageStatus(
        appId: app,
        used: Duration(minutes: used),
        limit: Duration(minutes: limit),
      );

  CommitmentLock compute({
    List<LimitRule> limits = const [],
    Map<String, UsageStatus> statuses = const {},
    List<ActiveMode> blocks = const [],
    QuietHours quiet = QuietHours.off,
    DateTime? now,
  }) =>
      policy.compute(
        now: now ?? noon,
        limits: limits,
        statuses: statuses,
        blocks: blocks,
        quiet: quiet,
        nextDayStart: (t) => calc.nextDayStart(t),
      );

  test('nothing is locked by default', () {
    final s = compute(limits: [rule('com.a', 30)], statuses: {'com.a': status('com.a', 10, 30)});
    expect(s.anyLock, isFalse);
    expect(s.isAppLocked('com.a'), isFalse);
    expect(s.anyLockUntil, isNull);
  });

  test('a limit that is used up locks the app until the day resets', () {
    final s = compute(limits: [rule('com.a', 30)], statuses: {'com.a': status('com.a', 30, 30)});
    expect(s.isAppLocked('com.a'), isTrue);
    expect(s.appLockedUntil('com.a'), DateTime(2026, 3, 11));
    expect(s.anyLock, isTrue);
  });

  test('a disabled limit never locks', () {
    final s = compute(
      limits: [LimitRule(appId: 'com.a', dailyLimit: const Duration(minutes: 30), enabled: false)],
      statuses: {'com.a': status('com.a', 99, 30)},
    );
    expect(s.anyLock, isFalse);
  });

  test('a running quick block locks its apps until it ends', () {
    final block = ActiveMode(
      id: 'quick-1',
      name: 'Instagram',
      packageNames: const ['com.ig'],
      endsAt: noon.add(const Duration(minutes: 2)),
    );
    final s = compute(blocks: [block]);
    expect(s.isAppLocked('com.ig'), isTrue);
    expect(s.appLockedUntil('com.ig'), block.endsAt);
    expect(s.isModeRunning('quick-1'), isTrue);
    expect(s.anyLockUntil, block.endsAt);
  });

  test('an expired block no longer locks', () {
    final block = ActiveMode(
      id: 'm1',
      name: 'Old',
      packageNames: const ['com.ig'],
      endsAt: noon.subtract(const Duration(seconds: 1)),
    );
    expect(compute(blocks: [block]).anyLock, isFalse);
  });

  test('overlapping locks keep the latest end per app and overall', () {
    final short = ActiveMode(
        id: 'a', name: 'A', packageNames: const ['com.x'], endsAt: noon.add(const Duration(minutes: 5)));
    final long = ActiveMode(
        id: 'b', name: 'B', packageNames: const ['com.x', 'com.y'], endsAt: noon.add(const Duration(hours: 2)));
    final s = compute(blocks: [short, long]);
    expect(s.appLockedUntil('com.x'), long.endsAt);
    expect(s.appLockedUntil('com.y'), long.endsAt);
    expect(s.anyLockUntil, long.endsAt);
  });

  test('a limit reached and a block combine to the later end', () {
    final block = ActiveMode(
        id: 'a', name: 'A', packageNames: const ['com.a'], endsAt: noon.add(const Duration(hours: 1)));
    final s = compute(
      limits: [rule('com.a', 30)],
      statuses: {'com.a': status('com.a', 30, 30)},
      blocks: [block],
    );
    expect(s.appLockedUntil('com.a'), DateTime(2026, 3, 11));
  });

  group('quiet hours', () {
    const overnight = QuietHours(enabled: true, startMinute: 22 * 60, endMinute: 7 * 60);

    test('lock limited apps while the window is active', () {
      final now = DateTime(2026, 3, 10, 23);
      final s = compute(limits: [rule('com.a', 30)], quiet: overnight, now: now);
      expect(s.isQuietActive, isTrue);
      expect(s.quietUntil, DateTime(2026, 3, 11, 7));
      expect(s.isAppLocked('com.a'), isTrue);
    });

    test('after midnight the window ends the same morning', () {
      final now = DateTime(2026, 3, 10, 3);
      final s = compute(limits: [rule('com.a', 30)], quiet: overnight, now: now);
      expect(s.quietUntil, DateTime(2026, 3, 10, 7));
    });

    test('outside the window nothing is locked', () {
      final s = compute(limits: [rule('com.a', 30)], quiet: overnight, now: noon);
      expect(s.isQuietActive, isFalse);
      expect(s.anyLock, isFalse);
    });

    test('without any limits quiet hours lock nothing', () {
      final s = compute(quiet: overnight, now: DateTime(2026, 3, 10, 23));
      expect(s.anyLock, isFalse);
    });
  });
}
