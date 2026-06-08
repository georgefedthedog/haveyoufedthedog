import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../household/current_household_controller.dart';
import 'subject.dart';

part 'subjects_controller.g.dart';

/// Loads the current household's subjects from PocketBase. Rebuilds whenever
/// the user switches household.
///
/// Returns an empty list if no household is currently selected.
@Riverpod(keepAlive: true)
class SubjectsController extends _$SubjectsController {
  @override
  Future<List<Subject>> build() async {
    final pb = ref.watch(pocketbaseClientProvider);
    final currentAsync = ref.watch(currentHouseholdControllerProvider);

    final current = currentAsync.valueOrNull;
    if (current == null) return const [];

    final records = await pb.collection('subjects').getFullList(
          filter: 'household = "${current.id}"',
          sort: 'sort_order,name',
        );

    return records.map(Subject.new).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
