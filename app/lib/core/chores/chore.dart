import 'package:pocketbase/pocketbase.dart';

import 'schedule_rule.dart';
import 'weekdays.dart';

/// Thin wrapper around a PocketBase `chores` record. Getters read the
/// fields directly off the [RecordModel] so we don't duplicate the schema
/// in a manual mapper - fields stay in sync with the server.
class Chore {
  final RecordModel record;
  const Chore(this.record);

  String get id => record.id;
  String get subjectId => record.data['subject'] as String;
  String get name => record.data['name'] as String;

  String get scheduleType => record.data['schedule_type'] as String;

  /// Whether this is a one-time chore ([ScheduleType.once]).
  bool get isOnce => scheduleType == ScheduleType.once.wire;
  int get hour => (record.data['hour'] as num).toInt();
  int get minute => (record.data['minute'] as num).toInt();
  int get weekdayMask =>
      (record.data['weekday_mask'] as num?)?.toInt() ?? Weekdays.all;

  /// Week cadence: 1 = every week (default), 2 = fortnightly.
  int get weekInterval {
    final raw = (record.data['week_interval'] as num?)?.toInt() ?? 1;
    return raw < 1 ? 1 : raw;
  }

  /// Fortnightly phase (0/1); only meaningful when [weekInterval] is 2.
  int get weekPhase => (record.data['week_phase'] as num?)?.toInt() ?? 0;

  /// Monthly: fixed-date vs Nth-weekday selection.
  MonthMode get monthMode =>
      MonthMode.fromWire(record.data['month_mode'] as String?);

  /// Monthly by-date day (1..28), or [ScheduleRule.last] for the last day.
  int get monthDay => (record.data['month_day'] as num?)?.toInt() ?? 1;

  /// Monthly by-weekday occurrence (1..4), or [ScheduleRule.last].
  int get monthOrdinal => (record.data['month_ordinal'] as num?)?.toInt() ?? 1;

  /// Monthly by-weekday day, ISO 1 (Mon) .. 7 (Sun).
  int get monthWeekday =>
      (record.data['month_weekday'] as num?)?.toInt() ?? DateTime.monday;

  bool get active => (record.data['active'] as bool?) ?? true;
  int get sortOrder => (record.data['sort_order'] as num?)?.toInt() ?? 0;

  /// One-time chores: the due date parsed from the `due_date` wire string
  /// (`YYYY-MM-DD`, date-only, no timezone - stored as text to dodge the tz
  /// shifts a real date field would bring). Null for recurring chores, or for
  /// an unset / malformed value.
  DateTime? get onceDate {
    final v = record.data['due_date'];
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  /// The chore's recurrence rule. Built fresh each call - cheap, and
  /// keeps the wrapper free of mutable state.
  ScheduleRule get rule => ScheduleRule(
    type: ScheduleType.fromWire(scheduleType),
    hour: hour,
    minute: minute,
    weekdayMask: weekdayMask,
    weekInterval: weekInterval,
    weekPhase: weekPhase,
    monthMode: monthMode,
    monthDay: monthDay,
    monthOrdinal: monthOrdinal,
    monthWeekday: monthWeekday,
    onceDate: onceDate,
  );
}
