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
    required ScheduleRule rule,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final rec = await pb.collection('chores').create(
      body: {
        'subject': subjectId,
        'name': name,
        ..._ruleFields(rule),
        'active': true,
        'sort_order': 0,
      },
    );
    _ref.invalidate(choresControllerProvider);
    return Chore(rec);
  }

  Future<Chore> updateChore(
    String id, {
    String? name,
    ScheduleRule? rule,
    bool? active,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    // The schedule is written as a whole - every field is authoritative, so
    // switching type clears the fields the old type used (no stale anchors).
    if (rule != null) body.addAll(_ruleFields(rule));
    if (active != null) body['active'] = active;
    final rec = await pb.collection('chores').update(id, body: body);
    _ref.invalidate(choresControllerProvider);
    return Chore(rec);
  }

  /// Flattens a [ScheduleRule] into the `chores` wire fields. Always writes
  /// the full set so a record never carries leftover values from a previous
  /// schedule type.
  static Map<String, dynamic> _ruleFields(ScheduleRule rule) => {
    'schedule_type': rule.type.wire,
    'hour': rule.hour,
    'minute': rule.minute,
    'weekday_mask': rule.weekdayMask,
    'week_interval': rule.weekInterval,
    'week_phase': rule.weekPhase,
    'month_mode': rule.monthMode.wire,
    'month_day': rule.monthDay,
    'month_ordinal': rule.monthOrdinal,
    'month_weekday': rule.monthWeekday,
    // Empty for any recurring type, so switching away from "once" clears a
    // stale date (the full-field-set rule). `YYYY-MM-DD`, no timezone.
    'due_date': rule.onceDate == null ? '' : _ymd(rule.onceDate!),
  };

  /// `YYYY-MM-DD` for the one-off `due_date` wire field.
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> deleteChore(String id) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('chores').delete(id);
    _ref.invalidate(choresControllerProvider);
  }
}
