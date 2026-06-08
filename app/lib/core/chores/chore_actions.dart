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
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final rec = await pb.collection('chores').create(body: {
      'subject': subjectId,
      'name': name,
      'schedule_type': scheduleType.wire,
      'hour': hour,
      'minute': minute,
      'weekday_mask': weekdayMask,
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
    bool? active,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (scheduleType != null) body['schedule_type'] = scheduleType.wire;
    if (hour != null) body['hour'] = hour;
    if (minute != null) body['minute'] = minute;
    if (weekdayMask != null) body['weekday_mask'] = weekdayMask;
    if (active != null) body['active'] = active;
    final rec = await pb.collection('chores').update(id, body: body);
    _ref.invalidate(choresControllerProvider);
    return Chore(rec);
  }

  Future<void> deleteChore(String id) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('chores').delete(id);
    _ref.invalidate(choresControllerProvider);
  }
}
