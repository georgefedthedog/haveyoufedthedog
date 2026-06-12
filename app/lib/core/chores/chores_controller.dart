import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../household/current_household_controller.dart';
import 'chore.dart';

part 'chores_controller.g.dart';

/// All chores in the current household, across every subject. The home
/// screen filters down to "due today" per-subject when rendering chips -
/// it's a small list and that derivation lives close to the UI.
///
/// One query per household instead of one per subject so the home screen
/// doesn't fan out on N requests.
@Riverpod(keepAlive: true)
class ChoresController extends _$ChoresController {
  @override
  Future<List<Chore>> build() async {
    final pbFuture = ref.watch(pocketbaseClientProvider.future);
    final currentAsync = ref.watch(currentHouseholdControllerProvider);

    final pb = await pbFuture;
    final current = currentAsync.valueOrNull;
    if (current == null) return const [];

    final records = await pb
        .collection('chores')
        .getFullList(
          // PocketBase supports relation dot-notation in filters.
          filter: 'subject.household = "${current.id}" && active = true',
          sort: 'sort_order,name',
        );

    return records.map(Chore.new).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
