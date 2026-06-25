import 'package:flutter/material.dart';

import 'weekdays.dart';

/// How often a chore recurs.
enum ScheduleType {
  daily,
  weekly,
  monthly;

  static ScheduleType fromWire(String? raw) {
    switch (raw) {
      case 'weekly':
        return ScheduleType.weekly;
      case 'monthly':
        return ScheduleType.monthly;
      default:
        return ScheduleType.daily;
    }
  }

  String get wire => name;
}

/// For [ScheduleType.monthly], how the day-of-month is chosen.
enum MonthMode {
  /// A fixed day number, or the last day - see [ScheduleRule.monthDay].
  day,

  /// The Nth (or last) given weekday - see [ScheduleRule.monthOrdinal] /
  /// [ScheduleRule.monthWeekday].
  weekday;

  static MonthMode fromWire(String? raw) =>
      raw == 'weekday' ? MonthMode.weekday : MonthMode.day;

  String get wire => name;
}

/// The recurrence rule for a chore - when it's due. Separated from
/// [Chore] so the same rule shape can be used by edit screens and future
/// notification scheduling without dragging the rest of a chore around.
class ScheduleRule {
  final ScheduleType type;
  final int hour;
  final int minute;

  /// Weekly: bitmask of days the chore is due (Mon=1 .. Sun=64).
  final int weekdayMask;

  /// Weekly cadence: 1 = every week, 2 = fortnightly.
  final int weekInterval;

  /// Weekly fortnightly phase: 0 or 1, picking which alternate weeks are
  /// "on". Measured against a fixed global epoch ([_weekEpoch]) so no per-chore
  /// anchor date is needed; ignored when [weekInterval] is 1. The edit screen
  /// turns a "this week / next week" choice into this via [weekPhaseForDate].
  final int weekPhase;

  /// Monthly: whether the due day is a fixed date or an Nth weekday.
  final MonthMode monthMode;

  /// Monthly [MonthMode.day]: the day of the month (1..28), or [last] for the
  /// final day of the month (handles short months / February).
  final int monthDay;

  /// Monthly [MonthMode.weekday]: which occurrence - 1..4, or [last].
  final int monthOrdinal;

  /// Monthly [MonthMode.weekday]: the weekday, ISO 1 (Mon) .. 7 (Sun).
  final int monthWeekday;

  /// Sentinel for [monthDay] / [monthOrdinal]: "the last one in the month"
  /// (last calendar day, or last occurrence of [monthWeekday]).
  static const int last = -1;

  /// First Monday of the Unix epoch (1970-01-05 UTC) - the fixed anchor all
  /// fortnightly parity is measured from. The worker crons use the same
  /// constant so the app and server agree on which weeks are "on".
  static final DateTime _weekEpoch = DateTime.utc(1970, 1, 5);

  const ScheduleRule({
    required this.type,
    required this.hour,
    required this.minute,
    this.weekdayMask = Weekdays.all,
    this.weekInterval = 1,
    this.weekPhase = 0,
    this.monthMode = MonthMode.day,
    this.monthDay = 1,
    this.monthOrdinal = 1,
    this.monthWeekday = DateTime.monday,
  });

  factory ScheduleRule.daily({required int hour, required int minute}) =>
      ScheduleRule(type: ScheduleType.daily, hour: hour, minute: minute);

  factory ScheduleRule.weekly({
    required int hour,
    required int minute,
    required int weekdayMask,
    int weekInterval = 1,
    int weekPhase = 0,
  }) => ScheduleRule(
    type: ScheduleType.weekly,
    hour: hour,
    minute: minute,
    weekdayMask: weekdayMask,
    weekInterval: weekInterval,
    weekPhase: weekPhase,
  );

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  bool isDueOn(DateTime day) {
    switch (type) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        if (!Weekdays.contains(weekdayMask, day)) return false;
        if (weekInterval <= 1) return true;
        return weeksSinceEpoch(day) % weekInterval == weekPhase;
      case ScheduleType.monthly:
        return _isDueMonthly(day);
    }
  }

  bool _isDueMonthly(DateTime day) {
    switch (monthMode) {
      case MonthMode.day:
        if (monthDay == last) return day.day == _daysInMonth(day);
        return day.day == monthDay;
      case MonthMode.weekday:
        if (day.weekday != monthWeekday) return false;
        // Last occurrence = no same-weekday day left in the month.
        if (monthOrdinal == last) return day.day + 7 > _daysInMonth(day);
        // Nth occurrence: the 1st of a weekday is days 1-7, 2nd is 8-14, etc.
        return (day.day - 1) ~/ 7 + 1 == monthOrdinal;
    }
  }

  /// Whole weeks from [_weekEpoch] to the Monday of [day]'s week. Both ends are
  /// UTC-midnight Mondays so the division is exact; round() guards float wobble.
  static int weeksSinceEpoch(DateTime day) {
    final dayMonday = _utcMonday(DateTime.utc(day.year, day.month, day.day));
    return (dayMonday.difference(_weekEpoch).inDays / 7).round();
  }

  /// Fortnightly phase (0/1) for the week containing [day]. The edit screen
  /// uses this to resolve "this week / next week" into a stored [weekPhase].
  static int weekPhaseForDate(DateTime day) => weeksSinceEpoch(day) % 2;

  /// Monday (00:00 UTC) of [u]'s week. [u] must already be a UTC date.
  static DateTime _utcMonday(DateTime u) =>
      u.subtract(Duration(days: u.weekday - 1));

  static int _daysInMonth(DateTime day) {
    final firstOfNext = day.month == 12
        ? DateTime(day.year + 1, 1, 1)
        : DateTime(day.year, day.month + 1, 1);
    return firstOfNext.subtract(const Duration(days: 1)).day;
  }

  /// Scheduled DateTime for a given calendar day, in local time.
  DateTime scheduledAt(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  /// [now] defaults to the wall clock; it only affects the fortnightly
  /// "this week / next week" suffix, which is relative to the current week.
  String humanLabel({DateTime? now}) {
    final tStr = _fmt(hour, minute);
    switch (type) {
      case ScheduleType.daily:
        return 'Every day at $tStr';
      case ScheduleType.weekly:
        return _weeklyLabel(tStr, now ?? DateTime.now());
      case ScheduleType.monthly:
        return '${_monthlyLabel()} at $tStr';
    }
  }

  String _weeklyLabel(String tStr, DateTime now) {
    final days = <String>[];
    for (var i = 0; i < 7; i++) {
      if ((weekdayMask & Weekdays.bits[i]) != 0) days.add(Weekdays.labels[i]);
    }
    if (days.isEmpty) return 'Never';

    // Every-week keeps the compact form ("Mon, Tue at ...", or "Every day"
    // when all seven). Fortnightly spells the days out, leads with the
    // cadence, and ends with whether *this* calendar week is the on-week.
    if (weekInterval <= 1) {
      final dayStr = days.length == 7 ? 'Every day' : days.join(', ');
      return '$dayStr at $tStr';
    }
    final onThisWeek = weeksSinceEpoch(now) % weekInterval == weekPhase;
    final when = onThisWeek ? 'this week' : 'next week';
    return 'Fortnightly on ${days.join(', ')} at $tStr · $when';
  }

  String _monthlyLabel() {
    switch (monthMode) {
      case MonthMode.day:
        if (monthDay == last) return 'Monthly on the last day';
        return 'Monthly on the ${ordinal(monthDay)}';
      case MonthMode.weekday:
        final wd = Weekdays.labels[monthWeekday - 1];
        final pos = monthOrdinal == last ? 'last' : _positionWord(monthOrdinal);
        return 'Monthly on the $pos $wd';
    }
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

  /// "1st", "2nd", "15th" - for the monthly-by-date label and the edit
  /// screen's day-of-month dropdown.
  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  static const _positions = ['first', 'second', 'third', 'fourth'];

  static String _positionWord(int n) =>
      (n >= 1 && n <= 4) ? _positions[n - 1] : ordinal(n);
}
