import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../household/current_household_controller.dart';
import 'completion.dart';

part 'today_completions_controller.g.dart';

/// Completions logged today (local-day) for the current household.
/// Backs the green/grey state of the chore-status chips on the home screen.
///
/// Day boundary is *local* — converted to UTC for the server filter, since
/// PocketBase stores `completed_at` in UTC.
@Riverpod(keepAlive: true)
class TodayCompletionsController extends _$TodayCompletionsController {
  @override
  Future<List<Completion>> build() async {
    final pbFuture = ref.watch(pocketbaseClientProvider.future);
    final currentAsync = ref.watch(currentHouseholdControllerProvider);

    final pb = await pbFuture;
    final current = currentAsync.valueOrNull;
    if (current == null) return const [];

    final now = DateTime.now();
    final startLocal = DateTime(now.year, now.month, now.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    final startUtc = startLocal.toUtc().toIso8601String();
    final endUtc = endLocal.toUtc().toIso8601String();

    final records = await pb.collection('completions').getFullList(
          filter:
              'subject.household = "${current.id}" && completed_at >= "$startUtc" && completed_at < "$endUtc"',
          sort: '-completed_at',
        );

    return records.map(Completion.new).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
