import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../household/current_household_controller.dart';
import 'subject.dart';

part 'subjects_controller.g.dart';

/// Loads the current household's subjects from PocketBase. Rebuilds whenever
/// the user switches household.
///
/// Returns an empty list if no household is currently selected.
///
/// **State-management notes:**
/// - All `ref.watch` calls happen before any `await`, so dependency
///   tracking survives the async boundary.
/// - Records are sorted by `sort_order` then `name` server-side via the
///   `sort` parameter so the UI doesn't have to re-sort.
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

    return records
        .map(
          (r) => Subject(
            id: r.id,
            householdId: r.data['household'] as String? ?? '',
            name: r.data['name'] as String? ?? '(unnamed)',
            icon: (r.data['icon'] as String?)?.isEmpty ?? true
                ? null
                : r.data['icon'] as String?,
            nfcTagId: (r.data['nfc_tag_id'] as String?)?.isEmpty ?? true
                ? null
                : r.data['nfc_tag_id'] as String?,
            sortOrder: (r.data['sort_order'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
