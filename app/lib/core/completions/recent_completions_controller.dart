import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import 'completion.dart';

part 'recent_completions_controller.g.dart';

/// Recent completions for one subject — backs the history list on the
/// subject detail screen. Family parameter: the subject id.
///
/// Uses `getList` with `perPage: 50` rather than `getFullList` — we don't
/// need every completion ever, just the recent ones. If history grows huge
/// we can paginate later.
@Riverpod(keepAlive: true)
class RecentCompletionsController extends _$RecentCompletionsController {
  @override
  Future<List<Completion>> build(String subjectId) async {
    final pb = await ref.watch(pocketbaseClientProvider.future);
    final result = await pb.collection('completions').getList(
          page: 1,
          perPage: 50,
          filter: 'subject = "$subjectId"',
          sort: '-completed_at',
        );
    return result.items.map(Completion.new).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
