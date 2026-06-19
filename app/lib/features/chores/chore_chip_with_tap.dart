import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/completion_actions.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/household/acting_user_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../completions/celebration_args.dart';
import 'chore_status_chip.dart';
import 'undo_confirm_dialog.dart';

/// Wraps [ChoreStatusChip] with toggle-to-log behaviour. The chip itself
/// stays presentational and reusable; the action lives here so it can be
/// dropped into anywhere we render today's chores (home, subject detail).
///
/// Tapping an outstanding chip logs a completion; tapping a completed chip
/// undoes the most recent completion of that chore.
class ChoreChipWithTap extends ConsumerWidget {
  final Chore chore;
  final String subjectId;
  final Completion? existingCompletion;

  const ChoreChipWithTap({
    super.key,
    required this.chore,
    required this.subjectId,
    required this.existingCompletion,
  });

  Future<void> _log(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(completionActionsProvider).logChore(
            subjectId: subjectId,
            choreId: chore.id,
            source: CompletionSource.button,
          );

      // Wait for the post-log invalidation of the recent-completions list
      // to settle so the streak provider has the new completion in scope
      // before we read it.
      await ref
          .read(recentCompletionsControllerProvider(subjectId).future);
      final streak = ref.read(subjectStreakProvider(subjectId));

      final subjects =
          ref.read(subjectsControllerProvider).valueOrNull ?? const [];
      String? iconToken;
      for (final s in subjects) {
        if (s.id == subjectId) {
          iconToken = s.icon;
          break;
        }
      }
      final character = ref.read(catalogProvider).lookupCharacter(iconToken);
      // The celebration names whoever the completion was logged *as* (the
      // "Act as" identity), not necessarily the signed-in user.
      final actingMember = await ref.read(actingMemberProvider.future);

      if (!context.mounted) return;
      context.push(
        Routes.celebration,
        extra: CelebrationArgs(
          character: character,
          choreName: chore.name,
          whoName: actingMember?.displayName,
          whoAvatar: actingMember?.avatar,
          streak: streak,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Could not log: $e'),
        showCloseIcon: true,
      ));
    }
  }

  Future<void> _undo(
      BuildContext context, WidgetRef ref, Completion completion) async {
    final messenger = ScaffoldMessenger.of(context);
    // You can undo a completion you logged - including one logged while
    // acting as the member who did it (completed_by == the acting id) - or
    // any of them if you're the household owner. Mirrors the server delete
    // rule; caught client-side so a disallowed undo doesn't round-trip into
    // a confusing 404.
    final actingUserId = ref.read(actingUserControllerProvider).valueOrNull;
    final isOwner =
        ref.read(currentHouseholdControllerProvider).valueOrNull?.isOwner ??
        false;
    if (completion.completedById != actingUserId && !isOwner) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(
        content: Text(
          "Switch to whoever logged this (or ask an owner) to undo it.",
        ),
      ));
      return;
    }
    if (!await confirmUndoCompletion(context, chore.name)) return;
    try {
      await ref.read(completionActionsProvider).undo(completion.id);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Removed: ${chore.name}'),
      ));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Could not undo: $e'),
        showCloseIcon: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completion = existingCompletion;
    return ChoreStatusChip(
      chore: chore,
      completion: completion,
      onTap: completion != null
          ? () => _undo(context, ref, completion)
          : () => _log(context, ref),
    );
  }
}
