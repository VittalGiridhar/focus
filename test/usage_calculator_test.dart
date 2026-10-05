import 'package:flutter_test/flutter_test.dart';
import 'package:focus/features/limits/domain/usage_calculator.dart';
import 'package:focus/features/limits/domain/usage_models.dart';

void main() {
  const calc = UsageCalculator();
  const app = 'instagram';

  UsageSession s(DateTime a, DateTime b, {String id = app}) =>
      UsageSession(appId: id, start: a, end: b);

  group('usage across multiple sessions (spec example)', () {
    final day = DateTime(2026, 3, 10);
    final sessions = [
      s(day.add(const Duration(hours: 10)), day.add(const Duration(hours: 10, minutes: 20))),
      s(day.add(const Duration(hours: 11)), day.add(const Duration(hours: 11, minutes: 40))),
    ];
    final rule = LimitRule(appId: app, dailyLimit: const Duration(hours: 1));

    test('limit reached at 11:40 after 20 + 40 minutes', () {
      final status = calc.statusFor(rule, sessions, day.add(const Duration(hours: 11, minutes: 40)));
      expect(status.used, const Duration(hours: 1));
      expect(status.isLimitReached, isTrue);
      expect(status.remaining, Duration.zero);
    });

    test('mid-second-session leaves correct remaining time', () {
      final status = calc.statusFor(rule, sessions, day.add(const Duration(hours: 11, minutes: 10)));
      expect(status.used, const Duration(minutes: 30));
      expect(status.remaining, const Duration(minutes: 30));
      expect(
        calc.projectedLimitTime(status, day.add(const Duration(hours: 11, minutes: 10))),
        day.add(const Duration(hours: 11, minutes: 40)),
      );
    });
  });

  group('robustness', () {
    final d = DateTime(2026, 3, 10, 9);

    test('overlapping duplicate events are not double counted', () {
      final used = calc.usedWithin(
        [s(d, d.add(const Duration(minutes: 30))), s(d.add(const Duration(minutes: 10)), d.add(const Duration(minutes: 40)))],
        appId: app,
        windowStart: DateTime(2026, 3, 10),
        windowEnd: DateTime(2026, 3, 11),
      );
      expect(used, const Duration(minutes: 40));
    });

    test('sessions are clamped to the window (cross-midnight)', () {
      final used = calc.usedWithin(
        [s(DateTime(2026, 3, 9, 23, 30), DateTime(2026, 3, 10, 0, 30))],
        appId: app,
        windowStart: DateTime(2026, 3, 10),
        windowEnd: DateTime(2026, 3, 11),
      );
      expect(used, const Duration(minutes: 30));
    });

    test('other apps and inverted (clock-changed) sessions are ignored', () {
      final used = calc.usedWithin(
        [s(d, d.add(const Duration(hours: 1)), id: 'youtube'), s(d.add(const Duration(hours: 2)), d)],
        appId: app,
        windowStart: DateTime(2026, 3, 10),
        windowEnd: DateTime(2026, 3, 11),
      );
      expect(used, Duration.zero);
    });
  });

  group('day boundaries', () {
    test('custom reset hour: 02:00 belongs to previous usage day with 04:00 reset', () {
      final start = calc.dayStart(DateTime(2026, 3, 10, 2), resetHour: 4);
      expect(start, DateTime(2026, 3, 9, 4));
    });

    test('nextDayStart uses calendar arithmetic', () {
      expect(calc.nextDayStart(DateTime(2026, 3, 10, 15)), DateTime(2026, 3, 11));
    });
  });

  group('limit validation', () {
    test('accepts 1 minute to 12 hours', () {
      expect(LimitRule.isValidLimit(const Duration(minutes: 1)), isTrue);
      expect(LimitRule.isValidLimit(const Duration(hours: 12)), isTrue);
    });

    test('rejects zero and over 12 hours', () {
      expect(LimitRule.isValidLimit(Duration.zero), isFalse);
      expect(LimitRule.isValidLimit(const Duration(hours: 12, minutes: 1)), isFalse);
    });
  });
}
