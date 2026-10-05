import 'package:equatable/equatable.dart';

const Duration kMaxDailyLimit = Duration(hours: 12);
const Duration kMinDailyLimit = Duration(minutes: 1);

class UsageSession extends Equatable {
  const UsageSession({
    required this.appId,
    required this.start,
    required this.end,
  });

  final String appId;
  final DateTime start;
  final DateTime end;

  Duration get duration => end.isAfter(start) ? end.difference(start) : Duration.zero;

  @override
  List<Object?> get props => [appId, start, end];
}

class LimitRule extends Equatable {
  // ignore: prefer_const_constructors_in_immutables
  LimitRule({
    required this.appId,
    required this.dailyLimit,
    this.label = '',
    this.enabled = true,
  }) : assert(
          dailyLimit >= kMinDailyLimit && dailyLimit <= kMaxDailyLimit,
          'dailyLimit must be between 1 minute and 12 hours',
        );

  final String appId;
  final Duration dailyLimit;
  final String label;
  final bool enabled;

  static bool isValidLimit(Duration d) => d >= kMinDailyLimit && d <= kMaxDailyLimit;

  @override
  List<Object?> get props => [appId, dailyLimit, label, enabled];
}

class UsageStatus extends Equatable {
  const UsageStatus({
    required this.appId,
    required this.used,
    required this.limit,
  });

  final String appId;
  final Duration used;
  final Duration limit;

  Duration get remaining => used >= limit ? Duration.zero : limit - used;
  bool get isLimitReached => used >= limit;

  @override
  List<Object?> get props => [appId, used, limit];
}
