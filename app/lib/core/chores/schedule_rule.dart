import 'package:flutter/material.dart';

import 'weekdays.dart';

/// How often a chore recurs. [once] is the odd one out - a single-shot task
/// with no recurrence; see [ScheduleRule.onceDate].
enum ScheduleType {
  daily,
  weekly,
  monthly,
  once;

  static ScheduleType fromWire(String? raw) {
    switch (raw) {
      case 'weekly':
        return ScheduleType.weekly;
      case 'monthly':
        return ScheduleType.monthly;
      case 'once':
        return ScheduleType.once;
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

  /// One-time ([ScheduleType.once]): the calendar date the task is due
  /// (date-only - the time of day is still [hour]/[minute]). A one-off carries
  /// over as overdue on every day from this date onward until it's completed,
  /// so [isDueOn] returns true for the target date and all days after. Null for
  /// every recurring type.
  final DateTime? onceDate;

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
    this.onceDate,
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

  /// A one-time task due on [onceDate] at [hour]:[minute]. The date is
  /// normalised to date-only so the carryover comparison in [isDueOn] is clean.
  factory ScheduleRule.once({
    required int hour,
    required int minute,
    required DateTime onceDate,
  }) => ScheduleRule(
    type: ScheduleType.once,
    hour: hour,
    minute: minute,
    onceDate: DateTime(onceDate.year, onceDate.month, onceDate.day),
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
      case ScheduleType.once:
        // Standing task: due on its date and every day after, until it's
        // completed (the home screen + retirement handle the "until completed"
        // part - the rule itself just never stops being due once the date
        // arrives). Compared date-only so the time of day doesn't matter.
        final target = onceDate;
        if (target == null) return false;
        final d = DateTime(day.year, day.month, day.day);
        final t = DateTime(target.year, target.month, target.day);
        return !d.isBefore(t);
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

  /// Scheduled DateTime for a given calendar day, in local time. A one-off
  /// ignores [day] - it has a single fixed instant on its [onceDate] - so its
  /// overdue / "due in" math stays anchored to the real date even once it's
  /// carried over to a later day (recurring types are always asked about the
  /// day they're due, so [day] is right for them).
  DateTime scheduledAt(DateTime day) {
    final d = (type == ScheduleType.once && onceDate != null) ? onceDate! : day;
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  // User-visible schedule sentences, clock strings, and ordinals live in
  // `schedule_labels.dart` (describeSchedule / formatClock / ordinalDay) -
  // they're locale-aware, this model isn't.
}
