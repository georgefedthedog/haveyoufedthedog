import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import 'schedule_rule.dart';
import 'weekdays.dart';

/// Localized rendering of [ScheduleRule]s and the app's clock/date strings.
/// The rule model itself stays locale-free - every user-visible schedule or
/// time label comes from here. Widgets call these with `context.l10n` (or
/// `context.l10n.localeName` for the pure formatters).

/// 2024-01-01 is a Monday, so ISO weekday `iso` of that week is 2024-01-iso.
DateTime _weekdayAnchor(int iso) => DateTime(2024, 1, iso);

/// 'Mon' / 'Mo.' / 'lun.' - short weekday name, ISO 1 (Mon) .. 7 (Sun).
String weekdayShort(int iso, String localeName) =>
    DateFormat.E(localeName).format(_weekdayAnchor(iso));

/// 'Monday' / 'Montag' / 'lundi' - full weekday name, ISO 1 .. 7.
String weekdayFull(int iso, String localeName) =>
    DateFormat.EEEE(localeName).format(_weekdayAnchor(iso));

/// "6:30 pm" in English (the design-language lowercase form, byte-identical
/// to the old `ScheduleRule.formatClock`) or 24-hour "18:30" everywhere
/// else. The one clock format for schedule and habit lines, so stacked
/// times read consistently. Never use `TimeOfDay.format` instead.
String formatClock(int h, int m, String localeName) {
  final mm = m.toString().padLeft(2, '0');
  if (localeName.startsWith('en')) {
    final period = h >= 12 ? 'pm' : 'am';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$mm $period';
  }
  return '${h.toString().padLeft(2, '0')}:$mm';
}

/// "1st" / "1." / "1er" - a day-of-month ordinal in the given locale. Used
/// inside the monthly schedule sentences and the day-of-month dropdown.
String ordinalDay(int n, String localeName) {
  switch (localeName.split('_').first) {
    case 'de':
      return '$n.';
    case 'fr':
      return n == 1 ? '1er' : '$n';
    case 'es':
      return '$n';
    default:
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
}

/// "30 Jun" / "30 Jun 2027" - the year only shows when it isn't the current
/// one, to keep the common case short.
String shortDate(DateTime d, String localeName, {DateTime? now}) {
  final pattern = d.year == (now ?? DateTime.now()).year ? 'd MMM' : 'd MMM y';
  return DateFormat(pattern, localeName).format(d);
}

/// "Wed, 30 Jun 2027" - the one-off date tile on the chore editor.
String fullDate(DateTime d, String localeName) =>
    DateFormat('EEE, d MMM y', localeName).format(d);

/// The localized schedule sentence - what used to be
/// `ScheduleRule.humanLabel`. [now] only affects the fortnightly
/// "this week / next week" suffix.
String describeSchedule(
  ScheduleRule rule,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final time = formatClock(rule.hour, rule.minute, l10n.localeName);
  switch (rule.type) {
    case ScheduleType.daily:
      return l10n.scheduleDaily(time);
    case ScheduleType.weekly:
      return _weekly(rule, l10n, time, now ?? DateTime.now());
    case ScheduleType.monthly:
      return _monthly(rule, l10n, time);
    case ScheduleType.once:
      final d = rule.onceDate;
      if (d == null) return l10n.scheduleOnceAt(time);
      return l10n.scheduleOnceOn(shortDate(d, l10n.localeName, now: now), time);
  }
}

String _weekly(
  ScheduleRule rule,
  AppLocalizations l10n,
  String time,
  DateTime now,
) {
  final names = <String>[];
  for (var i = 0; i < 7; i++) {
    if ((rule.weekdayMask & Weekdays.bits[i]) != 0) {
      names.add(weekdayShort(i + 1, l10n.localeName));
    }
  }
  if (names.isEmpty) return l10n.scheduleNever;

  // Every-week keeps the compact form; all seven days reads as daily.
  // Fortnightly spells the days out, leads with the cadence, and ends with
  // whether *this* calendar week is the on-week.
  if (rule.weekInterval <= 1) {
    if (names.length == 7) return l10n.scheduleDaily(time);
    return l10n.scheduleWeeklyAt(names.join(', '), time);
  }
  final onThisWeek =
      ScheduleRule.weeksSinceEpoch(now) % rule.weekInterval == rule.weekPhase;
  final phase = onThisWeek ? l10n.scheduleThisWeek : l10n.scheduleNextWeek;
  return l10n.scheduleFortnightly(names.join(', '), time, phase);
}

String _monthly(ScheduleRule rule, AppLocalizations l10n, String time) {
  switch (rule.monthMode) {
    case MonthMode.day:
      if (rule.monthDay == ScheduleRule.last) {
        return l10n.scheduleMonthlyLastDayAt(time);
      }
      return l10n.scheduleMonthlyOnDayAt(
        ordinalDay(rule.monthDay, l10n.localeName),
        time,
      );
    case MonthMode.weekday:
      final position = switch (rule.monthOrdinal) {
        1 => l10n.schedulePositionFirst,
        2 => l10n.schedulePositionSecond,
        3 => l10n.schedulePositionThird,
        4 => l10n.schedulePositionFourth,
        ScheduleRule.last => l10n.schedulePositionLast,
        _ => ordinalDay(rule.monthOrdinal, l10n.localeName),
      };
      return l10n.scheduleMonthlyOnWeekdayAt(
        position,
        weekdayShort(rule.monthWeekday, l10n.localeName),
        time,
      );
  }
}
