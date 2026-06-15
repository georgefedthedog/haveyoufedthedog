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

  /// Week cadence: 1 = every week (default), 2 = fortnightly, etc. Only
  /// meaningful for [ScheduleType.weekly].
  final int weekInterval;

  /// Anchor for [weekInterval] and earliest day the chore can be due. The
  /// week containing this date is an "on" week. Null (old records) means no
  /// anchor and no start gate - behaves as it always did.
  final DateTime? startDate;

  const ScheduleRule({
    required this.type,
    required this.hour,
    required this.minute,
    required this.weekdayMask,
    this.weekInterval = 1,
    this.startDate,
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
    int weekInterval = 1,
    DateTime? startDate,
  }) => ScheduleRule(
    type: ScheduleType.weekly,
    hour: hour,
    minute: minute,
    weekdayMask: weekdayMask,
    weekInterval: weekInterval,
    startDate: startDate,
  );

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  bool isDueOn(DateTime day) {
    switch (type) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        return Weekdays.contains(weekdayMask, day) && _isOnWeek(day);
    }
  }

  /// Whether [day] falls in an active week, given the fortnightly+ cadence
  /// and start anchor. Weeks are counted Mon→Sun from the anchor week, on
  /// UTC-normalised dates so there's no DST drift (chore times are
  /// wall-clock with no timezone).
  bool _isOnWeek(DateTime day) {
    final start = startDate;
    if (start == null) return true; // no anchor: every matching week
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    final startUtc = DateTime.utc(start.year, start.month, start.day);
    if (dayUtc.isBefore(startUtc)) return false; // not started yet
    if (weekInterval <= 1) return true;
    final weeks =
        _utcMonday(dayUtc).difference(_utcMonday(startUtc)).inDays ~/ 7;
    return weeks % weekInterval == 0;
  }

  /// Monday (00:00 UTC) of [u]'s week. [u] must already be a UTC date.
  static DateTime _utcMonday(DateTime u) =>
      u.subtract(Duration(days: u.weekday - 1));

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

    // Every-week keeps the compact form ("Mon, Tue at ...", or "Every day"
    // when all seven). Fortnightly+ leads with the cadence and spells the
    // days out: "Fortnightly on Mon at ...", "Every 4 weeks on Tue, Wed ...".
    if (weekInterval <= 1) {
      final dayStr = days.length == 7 ? 'Every day' : days.join(', ');
      return '$dayStr at $tStr';
    }
    final cadence =
        weekInterval == 2 ? 'Fortnightly' : 'Every $weekInterval weeks';
    return '$cadence on ${days.join(', ')} at $tStr';
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
