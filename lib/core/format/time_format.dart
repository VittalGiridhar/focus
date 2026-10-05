import 'package:flutter/material.dart';

/// "3:42 PM", or "tomorrow at 3:42 PM" when [end] falls on a later day than [now].
String endTimeLabel(BuildContext context, DateTime now, DateTime end) {
  final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(end));
  final sameDay = now.year == end.year && now.month == end.month && now.day == end.day;
  return sameDay ? time : 'tomorrow at $time';
}
