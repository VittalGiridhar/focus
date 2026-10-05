import 'package:equatable/equatable.dart';

import '../../limits/domain/usage_models.dart';

class DayUsage extends Equatable {
  const DayUsage({required this.day, required this.total});

  final DateTime day;
  final Duration total;

  @override
  List<Object?> get props => [day, total];
}

class AppTotal extends Equatable {
  const AppTotal({required this.appId, required this.label, required this.total});

  final String appId;
  final String label;
  final Duration total;

  @override
  List<Object?> get props => [appId, label, total];
}

class WeeklyUsage extends Equatable {
  const WeeklyUsage({required this.days, required this.topApps});

  /// Oldest first; the last entry is today.
  final List<DayUsage> days;
  final List<AppTotal> topApps;

  DayUsage get today => days.last;

  Duration get weekTotal => days.fold(Duration.zero, (s, d) => s + d.total);

  bool get hasData => weekTotal > Duration.zero;

  Duration get averagePerDay =>
      days.isEmpty ? Duration.zero : Duration(seconds: weekTotal.inSeconds ~/ days.length);

  /// Average of the days before today, used to compare today against.
  Duration get averageBeforeToday {
    final before = days.take(days.length - 1);
    if (before.isEmpty) return Duration.zero;
    final total = before.fold(Duration.zero, (s, d) => s + d.total);
    return Duration(seconds: total.inSeconds ~/ before.length);
  }

  int daysWithin(Duration goal) => days.where((d) => d.total <= goal).length;

  @override
  List<Object?> get props => [days, topApps];
}

class UsageAggregator {
  const UsageAggregator();

  /// Sums foreground time per calendar day for the last [dayCount] days ending
  /// today. Day boundaries use calendar arithmetic so DST days stay correct.
  WeeklyUsage weekly(
    Iterable<UsageSession> sessions,
    DateTime now, {
    required Map<String, String> labels,
    int dayCount = 7,
    int topCount = 5,
  }) {
    final starts = [
      for (var i = dayCount - 1; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    final totals = List<Duration>.filled(dayCount, Duration.zero);
    final perApp = <String, Duration>{};

    for (final s in sessions) {
      if (!labels.containsKey(s.appId)) continue;
      for (var i = 0; i < dayCount; i++) {
        final start = starts[i];
        final end = DateTime(start.year, start.month, start.day + 1);
        final from = s.start.isAfter(start) ? s.start : start;
        final to = s.end.isBefore(end) ? s.end : end;
        if (!to.isAfter(from)) continue;
        final d = to.difference(from);
        totals[i] += d;
        perApp[s.appId] = (perApp[s.appId] ?? Duration.zero) + d;
      }
    }

    final top = perApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return WeeklyUsage(
      days: [for (var i = 0; i < dayCount; i++) DayUsage(day: starts[i], total: totals[i])],
      topApps: [
        for (final e in top.take(topCount))
          AppTotal(appId: e.key, label: labels[e.key]!, total: e.value),
      ],
    );
  }
}

/// A short, non-judgemental line for the Insights screen.
String gentleMessage(WeeklyUsage usage, Duration? goal) {
  if (!usage.hasData) {
    return 'Nothing recorded yet. Check back after a few days of use.';
  }
  if (goal != null) {
    final within = usage.daysWithin(goal);
    final n = usage.days.length;
    return within * 2 >= n
        ? 'You stayed within your goal on $within of $n days.'
        : 'Some days run long, and that\'s okay. One small step tomorrow is enough.';
  }
  return usage.today.total < usage.averageBeforeToday
      ? 'Today is lighter than your usual. Nice.'
      : 'Every day is a fresh start.';
}
