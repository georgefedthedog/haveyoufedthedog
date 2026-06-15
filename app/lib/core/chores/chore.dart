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
  int get hour => (record.data['hour'] as num).toInt();
  int get minute => (record.data['minute'] as num).toInt();
  int get weekdayMask =>
      (record.data['weekday_mask'] as num?)?.toInt() ?? Weekdays.all;

  /// Week cadence: 1 = every week (default), 2 = fortnightly, etc.
  int get weekInterval {
    final raw = (record.data['week_interval'] as num?)?.toInt() ?? 1;
    return raw < 1 ? 1 : raw;
  }

  /// Anchor / earliest due day, as a pure calendar date. Stored as UTC
  /// midnight and kept in UTC so the y/m/d round-trip exactly (no tz
  /// rollback) - [ScheduleRule] compares it against day-level UTC dates.
  DateTime? get startDate {
    final raw = record.data['start_date'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool get active => (record.data['active'] as bool?) ?? true;
  int get sortOrder => (record.data['sort_order'] as num?)?.toInt() ?? 0;

  /// The chore's recurrence rule. Built fresh each call - cheap, and
  /// keeps the wrapper free of mutable state.
  ScheduleRule get rule => ScheduleRule(
    type: ScheduleType.fromWire(scheduleType),
    hour: hour,
    minute: minute,
    weekdayMask: weekdayMask,
    weekInterval: weekInterval,
    startDate: startDate,
  );
}
