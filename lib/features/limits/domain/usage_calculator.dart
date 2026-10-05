import 'usage_models.dart';

class UsageCalculator {
  const UsageCalculator();

  /// Start of the usage day containing [moment], where the day rolls over at
  /// [resetHour]:[resetMinute] local time.
  DateTime dayStart(DateTime moment, {int resetHour = 0, int resetMinute = 0}) {
    final candidate = DateTime(moment.year, moment.month, moment.day, resetHour, resetMinute);
    return candidate.isAfter(moment)
        ? DateTime(moment.year, moment.month, moment.day - 1, resetHour, resetMinute)
        : candidate;
  }

  /// Start of the next usage day. Uses calendar arithmetic so DST days
  /// (23h/25h) are handled correctly.
  DateTime nextDayStart(DateTime moment, {int resetHour = 0, int resetMinute = 0}) {
    final start = dayStart(moment, resetHour: resetHour, resetMinute: resetMinute);
    return DateTime(start.year, start.month, start.day + 1, resetHour, resetMinute);
  }

  /// Total foreground time for [appId] within [windowStart, windowEnd),
  /// clamping sessions to the window and merging overlaps so duplicated or
  /// overlapping OS events are not double counted.
  Duration usedWithin(
    Iterable<UsageSession> sessions, {
    required String appId,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final clamped = <(DateTime, DateTime)>[];
    for (final s in sessions) {
      if (s.appId != appId) continue;
      final start = s.start.isBefore(windowStart) ? windowStart : s.start;
      final end = s.end.isAfter(windowEnd) ? windowEnd : s.end;
      if (end.isAfter(start)) clamped.add((start, end));
    }
    if (clamped.isEmpty) return Duration.zero;
    clamped.sort((a, b) => a.$1.compareTo(b.$1));

    var total = Duration.zero;
    var curStart = clamped.first.$1;
    var curEnd = clamped.first.$2;
    for (final (start, end) in clamped.skip(1)) {
      if (start.isAfter(curEnd)) {
        total += curEnd.difference(curStart);
        curStart = start;
        curEnd = end;
      } else if (end.isAfter(curEnd)) {
        curEnd = end;
      }
    }
    return total + curEnd.difference(curStart);
  }

  UsageStatus statusFor(
    LimitRule rule,
    Iterable<UsageSession> sessions,
    DateTime now, {
    int resetHour = 0,
    int resetMinute = 0,
  }) {
    final start = dayStart(now, resetHour: resetHour, resetMinute: resetMinute);
    final used = usedWithin(
      sessions,
      appId: rule.appId,
      windowStart: start,
      windowEnd: now,
    );
    return UsageStatus(appId: rule.appId, used: used, limit: rule.dailyLimit);
  }

  /// When the limit would be hit if the app stays in the foreground from [now].
  /// Returns null if the limit is already reached.
  DateTime? projectedLimitTime(UsageStatus status, DateTime now) {
    if (status.isLimitReached) return null;
    return now.add(status.remaining);
  }
}
