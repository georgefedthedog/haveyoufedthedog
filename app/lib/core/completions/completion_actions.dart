import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'completion.dart';
import 'today_completions_controller.dart';

part 'completion_actions.g.dart';

/// Side-effect provider exposing imperative completion operations.
@Riverpod(keepAlive: true)
CompletionActions completionActions(Ref ref) => CompletionActions(ref);

/// **Not** a Riverpod notifier — actions don't have their own state. State
/// lives in `TodayCompletionsController` (and future per-subject lists).
class CompletionActions {
  final Ref _ref;
  CompletionActions(this._ref);

  Future<String> _currentUserId() async {
    final auth = await _ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (userId == null) {
      throw StateError('Cannot log a completion when signed out.');
    }
    return userId;
  }

  /// Log a completion of [choreId] for [subjectId], attributed to [source].
  /// Returns the new [Completion] so callers can offer Undo.
  Future<Completion> logChore({
    required String subjectId,
    required String choreId,
    required CompletionSource source,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final userId = await _currentUserId();
    final now = DateTime.now().toUtc();
    final rec = await pb.collection('completions').create(body: {
      'subject': subjectId,
      'chore': choreId,
      'completed_at': now.toIso8601String(),
      'completed_by': userId,
      'source': source.wire,
    });
    _ref.invalidate(todayCompletionsControllerProvider);
    return Completion(rec);
  }

  /// Delete a completion by id. Used by the Undo snackbar action.
  Future<void> undo(String completionId) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('completions').delete(completionId);
    _ref.invalidate(todayCompletionsControllerProvider);
  }
}
