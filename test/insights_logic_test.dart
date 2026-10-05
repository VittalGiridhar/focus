import 'package:flutter_test/flutter_test.dart';
import 'package:focus/features/insights/domain/usage_aggregator.dart';
import 'package:focus/features/limits/domain/usage_models.dart';
import 'package:focus/features/settings/domain/quiet_hours.dart';

void main() {
  const agg = UsageAggregator();
  final now = DateTime(2026, 3, 10, 15);
  const labels = {'com.yt': 'YouTube', 'com.ig': 'Instagram'};

  UsageSession s(String app, DateTime a, Duration d) =>
      UsageSession(appId: app, start: a, end: a.add(d));

  group('weekly aggregation', () {
    test('returns seven days ending today, oldest first', () {
      final w = agg.weekly(const [], now, labels: labels);
      expect(w.days.length, 7);
      expect(w.days.first.day, DateTime(2026, 3, 4));
      expect(w.days.last.day, DateTime(2026, 3, 10));
      expect(w.hasData, isFalse);
    });

    test('sums sessions per day and ranks apps', () {
      final w = agg.weekly([
        s('com.yt', DateTime(2026, 3, 10, 10), const Duration(minutes: 40)),
        s('com.ig', DateTime(2026, 3, 10, 12), const Duration(minutes: 20)),
        s('com.yt', DateTime(2026, 3, 9, 20), const Duration(minutes: 30)),
      ], now, labels: labels);
      expect(w.today.total, const Duration(hours: 1));
      expect(w.days[5].total, const Duration(minutes: 30));
      expect(w.topApps.map((a) => a.label), ['YouTube', 'Instagram']);
      expect(w.topApps.first.total, const Duration(minutes: 70));
    });

    test('a session crossing midnight is split across both days', () {
      final w = agg.weekly([
        s('com.yt', DateTime(2026, 3, 9, 23, 30), const Duration(hours: 1)),
      ], now, labels: labels);
      expect(w.days[5].total, const Duration(minutes: 30));
      expect(w.today.total, const Duration(minutes: 30));
    });

    test('apps outside the label map (system apps) are ignored', () {
      final w = agg.weekly([
        s('com.android.launcher', DateTime(2026, 3, 10, 9), const Duration(hours: 3)),
      ], now, labels: labels);
      expect(w.hasData, isFalse);
    });

    test('sessions older than the window are ignored', () {
      final w = agg.weekly([
        s('com.yt', DateTime(2026, 3, 1, 9), const Duration(hours: 2)),
      ], now, labels: labels);
      expect(w.hasData, isFalse);
    });

    test('only the top five apps are returned', () {
      final many = {for (var i = 0; i < 8; i++) 'com.$i': 'App $i'};
      final w = agg.weekly([
        for (var i = 0; i < 8; i++)
          s('com.$i', DateTime(2026, 3, 10, 8), Duration(minutes: 10 + i)),
      ], now, labels: many);
      expect(w.topApps.length, 5);
      expect(w.topApps.first.label, 'App 7');
    });

    test('averages and goal counting', () {
      final w = agg.weekly([
        for (var d = 4; d <= 10; d++)
          s('com.yt', DateTime(2026, 3, d, 9), Duration(hours: d == 10 ? 1 : 3)),
      ], now, labels: labels);
      expect(w.daysWithin(const Duration(hours: 2)), 1);
      expect(w.daysWithin(const Duration(hours: 3)), 7);
      expect(w.averageBeforeToday, const Duration(hours: 3));
      expect(w.averagePerDay, Duration(seconds: (6 * 3 + 1) * 3600 ~/ 7));
    });

    test('DST spring-forward day is still one calendar day', () {
      // Dates are local; a session across the 23-hour day stays within it.
      final dstNow = DateTime(2026, 3, 8, 22);
      final w = agg.weekly([
        s('com.yt', DateTime(2026, 3, 8, 21), const Duration(hours: 1)),
      ], dstNow, labels: labels);
      expect(w.today.total, const Duration(hours: 1));
    });
  });

  group('gentle messages', () {
    WeeklyUsage week(List<int> minutes) => WeeklyUsage(
          days: [
            for (var i = 0; i < minutes.length; i++)
              DayUsage(day: DateTime(2026, 3, 4 + i), total: Duration(minutes: minutes[i])),
          ],
          topApps: const [],
        );

    test('no data', () {
      expect(gentleMessage(week([0, 0, 0, 0, 0, 0, 0]), null), contains('Nothing recorded'));
    });

    test('lighter today than usual', () {
      expect(gentleMessage(week([120, 120, 120, 120, 120, 120, 30]), null),
          'Today is lighter than your usual. Nice.');
    });

    test('heavier today stays neutral, never judgemental', () {
      expect(gentleMessage(week([30, 30, 30, 30, 30, 30, 200]), null),
          'Every day is a fresh start.');
    });

    test('goal met on most days', () {
      expect(gentleMessage(week([60, 60, 60, 60, 200, 200, 60]), const Duration(hours: 2)),
          'You stayed within your goal on 5 of 7 days.');
    });

    test('goal missed on most days is encouraging', () {
      final msg = gentleMessage(week([300, 300, 300, 300, 300, 60, 60]), const Duration(hours: 2));
      expect(msg, contains('okay'));
      expect(msg.toLowerCase(), isNot(contains('fail')));
    });
  });

  group('quiet hours', () {
    const overnight = QuietHours(enabled: true, startMinute: 22 * 60, endMinute: 7 * 60);

    test('wraps past midnight, start inclusive, end exclusive', () {
      expect(overnight.isActiveAtMinute(22 * 60), isTrue);
      expect(overnight.isActiveAtMinute(30), isTrue);
      expect(overnight.isActiveAtMinute(7 * 60 - 1), isTrue);
      expect(overnight.isActiveAtMinute(7 * 60), isFalse);
      expect(overnight.isActiveAtMinute(12 * 60), isFalse);
    });

    test('same-day window', () {
      const day = QuietHours(enabled: true, startMinute: 13 * 60, endMinute: 14 * 60);
      expect(day.isActiveAt(DateTime(2026, 1, 1, 13, 30)), isTrue);
      expect(day.isActiveAt(DateTime(2026, 1, 1, 14)), isFalse);
    });

    test('disabled or empty windows are never active and an empty one is invalid', () {
      expect(overnight.copyWith(enabled: false).isActiveAtMinute(23 * 60), isFalse);
      const empty = QuietHours(enabled: true, startMinute: 600, endMinute: 600);
      expect(empty.isValid, isFalse);
      expect(empty.isActiveAtMinute(600), isFalse);
    });
  });
}
