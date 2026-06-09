import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/completion_actions.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../completions/completion_celebration.dart';
import 'chore_status_chip.dart';

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

      final subjects =
          ref.read(subjectsControllerProvider).valueOrNull ?? const [];
      String? iconToken;
      for (final s in subjects) {
        if (s.id == subjectId) {
          iconToken = s.icon;
          break;
        }
      }
      final character = CharacterRegistry.lookup(iconToken);
      final whoName =
          ref.read(authControllerProvider).valueOrNull?.displayName;

      if (!context.mounted) return;
      await CompletionCelebration.show(
        context,
        character: character,
        choreName: chore.name,
        whoName: whoName,
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
    // PB's delete rule only allows the original logger (or household
    // owners) to remove a completion. Catch the "not yours" case
    // client-side so it doesn't round-trip into a confusing 404.
    final myUserId = ref.read(authControllerProvider).valueOrNull?.userId;
    if (completion.completedById != myUserId) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(
        content: Text("Only the person who logged it can undo."),
      ));
      return;
    }
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
