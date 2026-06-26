import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../household/current_household_controller.dart';

part 'completed_once_chores_controller.g.dart';

/// Chore ids of one-off (`schedule_type = once`) chores in the current
/// household that have *any* completion. A one-off's first completion is
/// terminal, so membership here means "this one-off is done for good".
///
/// The home screen uses it to retire a finished one-off the day after it's
/// logged: it shows as done on its completion day (via the today-completions
/// list), then this set hides it - covering the gap between local midnight and
/// when the worker flips the chore inactive, so it never flashes back as
/// "pending". Bumped alongside the other read-side lists when a completion is
/// logged or undone.
@Riverpod(keepAlive: true)
class CompletedOnceChoreIdsController extends _$CompletedOnceChoreIdsController {
  @override
  Future<Set<String>> build() async {
    final pbFuture = ref.watch(pocketbaseClientProvider.future);
    final currentAsync = ref.watch(currentHouseholdControllerProvider);

    final pb = await pbFuture;
    final current = currentAsync.valueOrNull;
    if (current == null) return const {};

    // Only the `chore` id is needed; one-offs are few, so this stays tiny.
    final records = await pb
        .collection('completions')
        .getFullList(
          filter:
              'subject.household = "${current.id}" && chore.schedule_type = "once"',
          fields: 'chore',
        );

    return {
      for (final r in records)
        if ((r.data['chore'] as String?)?.isNotEmpty ?? false)
          r.data['chore'] as String,
    };
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
