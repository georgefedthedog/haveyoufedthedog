import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import 'chore.dart';
import 'chores_controller.dart';
import 'schedule_rule.dart';

part 'chore_actions.g.dart';

/// Side-effect provider exposing imperative chore operations.
@Riverpod(keepAlive: true)
ChoreActions choreActions(Ref ref) => ChoreActions(ref);

class ChoreActions {
  final Ref _ref;
  ChoreActions(this._ref);

  Future<Chore> createChore({
    required String subjectId,
    required String name,
    required ScheduleType scheduleType,
    required int hour,
    required int minute,
    required int weekdayMask,
    int weekInterval = 1,
    DateTime? startDate,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final rec = await pb.collection('chores').create(body: {
      'subject': subjectId,
      'name': name,
      'schedule_type': scheduleType.wire,
      'hour': hour,
      'minute': minute,
      'weekday_mask': weekdayMask,
      'week_interval': weekInterval,
      'start_date': _wireDate(startDate),
      'active': true,
      'sort_order': 0,
    });
    _ref.invalidate(choresControllerProvider);
    return Chore(rec);
  }

  Future<Chore> updateChore(
    String id, {
    String? name,
    ScheduleType? scheduleType,
    int? hour,
    int? minute,
    int? weekdayMask,
    int? weekInterval,
    DateTime? startDate,
    bool? active,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (scheduleType != null) body['schedule_type'] = scheduleType.wire;
    if (hour != null) body['hour'] = hour;
    if (minute != null) body['minute'] = minute;
    if (weekdayMask != null) body['weekday_mask'] = weekdayMask;
    // Cadence + anchor travel together: setting the interval authoritatively
    // writes the anchor too, so switching back to weekly clears a stale date.
    if (weekInterval != null) {
      body['week_interval'] = weekInterval;
      body['start_date'] = _wireDate(startDate);
    }
    if (active != null) body['active'] = active;
    final rec = await pb.collection('chores').update(id, body: body);
    _ref.invalidate(choresControllerProvider);
    return Chore(rec);
  }

  /// A calendar date serialised as UTC midnight so it round-trips as a pure
  /// day (see [Chore.startDate]). Empty string clears the field.
  static String _wireDate(DateTime? date) => date == null
      ? ''
      : DateTime.utc(date.year, date.month, date.day).toIso8601String();

  Future<void> deleteChore(String id) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('chores').delete(id);
    _ref.invalidate(choresControllerProvider);
  }
}
