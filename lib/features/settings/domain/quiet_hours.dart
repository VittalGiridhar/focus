import 'package:equatable/equatable.dart';

class QuietHours extends Equatable {
  const QuietHours({
    required this.enabled,
    required this.startMinute,
    required this.endMinute,
  });

  static const off = QuietHours(enabled: false, startMinute: 22 * 60, endMinute: 7 * 60);

  final bool enabled;
  final int startMinute;
  final int endMinute;

  bool get isValid =>
      startMinute != endMinute &&
      startMinute >= 0 &&
      startMinute < 1440 &&
      endMinute >= 0 &&
      endMinute < 1440;

  QuietHours copyWith({bool? enabled, int? startMinute, int? endMinute}) => QuietHours(
        enabled: enabled ?? this.enabled,
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
      );

  /// Whether [minuteOfDay] falls inside the window (start inclusive, end
  /// exclusive). Windows may wrap past midnight, e.g. 22:00 to 07:00.
  bool isActiveAtMinute(int minuteOfDay) {
    if (!enabled || !isValid) return false;
    return startMinute < endMinute
        ? minuteOfDay >= startMinute && minuteOfDay < endMinute
        : minuteOfDay >= startMinute || minuteOfDay < endMinute;
  }

  bool isActiveAt(DateTime t) => isActiveAtMinute(t.hour * 60 + t.minute);

  @override
  List<Object?> get props => [enabled, startMinute, endMinute];
}
