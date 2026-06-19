import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../chores/chore.dart';
import '../household/acting_user_controller.dart';
import 'completion.dart';
import 'household_history_controller.dart';
import 'recent_completions_controller.dart';
import 'today_completions_controller.dart';

part 'completion_actions.g.dart';

/// Side-effect provider exposing imperative completion operations.
@Riverpod(keepAlive: true)
CompletionActions completionActions(Ref ref) => CompletionActions(ref);

/// **Not** a Riverpod notifier - actions don't have their own state. State
/// lives in `TodayCompletionsController` (and future per-subject lists).
class CompletionActions {
  final Ref _ref;
  CompletionActions(this._ref);

  /// The id to stamp on `completed_by` - the "Act as" identity, which
  /// defaults to the signed-in user. Logging as another member only succeeds
  /// once the server's completions rule is relaxed (it still accepts a
  /// self-attributed write either way).
  Future<String> _actingUserId() async {
    final id = await _ref.read(actingUserControllerProvider.future);
    if (id == null) {
      throw StateError('Cannot log a completion when signed out.');
    }
    return id;
  }

  /// Log a completion of [choreId] for [subjectId], attributed to [source].
  /// Returns the new [Completion] so callers can offer Undo.
  Future<Completion> logChore({
    required String subjectId,
    required String choreId,
    required CompletionSource source,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final actingUserId = await _actingUserId();
    final now = DateTime.now().toUtc();
    final rec = await pb
        .collection('completions')
        .create(
          body: {
            'subject': subjectId,
            'chore': choreId,
            'completed_at': now.toIso8601String(),
            'completed_by': actingUserId,
            'source': source.wire,
          },
        );
    _bump(subjectId);
    return Completion(rec);
  }

  /// Delete a completion by id. Used by the Undo snackbar action.
  Future<void> undo(String completionId) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    // Look up the subject first so we can invalidate the right per-subject
    // recent list. If the record is already gone, skip the bump.
    String? subjectId;
    try {
      final rec = await pb.collection('completions').getOne(completionId);
      subjectId = rec.data['subject'] as String?;
    } catch (_) {}
    await pb.collection('completions').delete(completionId);
    _bump(subjectId);
  }

  /// Picks the best chore for [subjectId] right now and logs it, attributed
  /// to [source]. Used by NFC quick-log.
  ///
  /// "Best" = active, due today, not already logged today. Overdue chores
  /// win first (latest-scheduled overdue wins among overdue), otherwise
  /// the next scheduled one wins.
  ///
  /// Returns the chosen [Chore] paired with the new [Completion], or null
  /// if there's nothing left to log (everything caught up for today).
  Future<({Chore chore, Completion completion})?> logBestChoreFor(
    String subjectId, {
    required CompletionSource source,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final end = start.add(const Duration(days: 1));

    final choreRecords = await pb
        .collection('chores')
        .getFullList(filter: 'subject = "$subjectId" && active = true');
    final todays = await pb
        .collection('completions')
        .getFullList(
          filter:
              'subject = "$subjectId" && completed_at >= "${start.toIso8601String()}" && completed_at < "${end.toIso8601String()}"',
        );
    final loggedChoreIds = <String>{
      for (final r in todays)
        if ((r.data['chore'] as String?)?.isNotEmpty ?? false)
          r.data['chore'] as String,
    };

    final candidates = choreRecords
        .map(Chore.new)
        .where((c) => c.rule.isDueOn(now))
        .where((c) => !loggedChoreIds.contains(c.id))
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final aScheduled = a.rule.scheduledAt(now);
      final bScheduled = b.rule.scheduledAt(now);
      final aOverdue = !aScheduled.isAfter(now);
      final bOverdue = !bScheduled.isAfter(now);
      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      // Both overdue: most recently-scheduled one wins (you probably just
      // missed this one). Neither overdue: next one wins.
      return aOverdue
          ? bScheduled.compareTo(aScheduled)
          : aScheduled.compareTo(bScheduled);
    });

    final pick = candidates.first;
    final completion = await logChore(
      subjectId: subjectId,
      choreId: pick.id,
      source: source,
    );
    return (chore: pick, completion: completion);
  }

  /// Invalidate the read-side providers so they refetch and the UI picks
  /// up the new state. The household-wide history is the data source for
  /// the leaderboard, weekly stats, and household-streak providers - bump
  /// it so those re-derive without the user having to pull-to-refresh.
  void _bump(String? subjectId) {
    _ref.invalidate(todayCompletionsControllerProvider);
    _ref.invalidate(householdHistoryControllerProvider);
    if (subjectId != null) {
      _ref.invalidate(recentCompletionsControllerProvider(subjectId));
    }
  }
}
