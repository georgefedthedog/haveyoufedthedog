import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../household/current_household_controller.dart';
import 'completion.dart';

part 'household_history_controller.g.dart';

/// Recent completions across every subject in the current household. Used
/// by the History tab. Returns the last `perPage` entries (100 by default
/// - small households' "everything since forever" fits comfortably).
@Riverpod(keepAlive: true)
class HouseholdHistoryController extends _$HouseholdHistoryController {
  static const _perPage = 100;

  @override
  Future<List<Completion>> build() async {
    final pb = await ref.watch(pocketbaseClientProvider.future);
    final currentAsync = ref.watch(currentHouseholdControllerProvider);
    final current = currentAsync.valueOrNull;
    if (current == null) return const [];

    final result = await pb
        .collection('completions')
        .getList(
          page: 1,
          perPage: _perPage,
          filter: 'subject.household = "${current.id}"',
          sort: '-completed_at',
        );
    return result.items.map(Completion.new).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
