import 'package:flutter/material.dart';

import 'weekdays.dart';

/// How often a chore recurs.
enum ScheduleType {
  daily,
  weekly;

  static ScheduleType fromWire(String? raw) =>
      raw == 'weekly' ? ScheduleType.weekly : ScheduleType.daily;

  String get wire => name;
}

/// The recurrence rule for a chore - when it's due. Separated from
/// [Chore] so the same rule shape can be used by edit screens and future
/// notification scheduling without dragging the rest of a chore around.
class ScheduleRule {
  final ScheduleType type;
  final int hour;
  final int minute;
  final int weekdayMask;

  const ScheduleRule({
    required this.type,
    required this.hour,
    required this.minute,
    required this.weekdayMask,
  });

  factory ScheduleRule.daily({required int hour, required int minute}) =>
      ScheduleRule(
        type: ScheduleType.daily,
        hour: hour,
        minute: minute,
        weekdayMask: Weekdays.all,
      );

  factory ScheduleRule.weekly({
    required int hour,
    required int minute,
    required int weekdayMask,
  }) => ScheduleRule(
    type: ScheduleType.weekly,
    hour: hour,
    minute: minute,
    weekdayMask: weekdayMask,
  );

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  bool isDueOn(DateTime day) {
    switch (type) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        return Weekdays.contains(weekdayMask, day);
    }
  }

  /// Scheduled DateTime for a given calendar day, in local time.
  DateTime scheduledAt(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  String humanLabel() {
    final tStr = _fmt(hour, minute);
    if (type == ScheduleType.daily) return 'Every day at $tStr';
    final days = <String>[];
    for (var i = 0; i < 7; i++) {
      if ((weekdayMask & Weekdays.bits[i]) != 0) days.add(Weekdays.labels[i]);
    }
    if (days.isEmpty) return 'Never';
    if (days.length == 7) return 'Every day at $tStr';
    return '${days.join(", ")} at $tStr';
  }

  /// "6:30 pm" - the one clock format for schedule and habit lines, so
  /// stacked times read consistently.
  static String formatClock(int h, int m) {
    final period = h >= 12 ? 'pm' : 'am';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final mm = m.toString().padLeft(2, '0');
    return '$h12:$mm $period';
  }

  static String _fmt(int h, int m) => formatClock(h, m);
}
