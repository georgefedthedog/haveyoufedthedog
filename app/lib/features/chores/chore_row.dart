import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/completion_actions.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../completions/celebration_args.dart';

/// A wide, tappable row representing one chore for today on the subject
/// detail screen. Renders the chore name + schedule line; trailing shows
/// either the completed time + a green tick (when logged today) or the
/// scheduled time + an outlined circle (when still outstanding).
///
/// Same toggle-on-tap semantics as [ChoreChipWithTap]: tap an outstanding
/// row to log; tap a completed row (logged by you) to undo. Tapping a row
/// logged by someone else shows an explainer snackbar.
class ChoreRow extends ConsumerWidget {
  final Chore chore;
  final String subjectId;
  final Completion? existingCompletion;

  const ChoreRow({
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

      // Show the celebration overlay. Look up the subject so we can pick
      // the right character (and the user's name for "logged by …").
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
      context.push(
        Routes.celebration,
        extra: CelebrationArgs(
          character: character,
          choreName: chore.name,
          whoName: whoName,
          streak: streak,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('Could not log: $e'),
      ));
    }
  }

  Future<void> _undo(
      BuildContext context, WidgetRef ref, Completion completion) async {
    final messenger = ScaffoldMessenger.of(context);
    final myUserId = ref.read(authControllerProvider).valueOrNull?.userId;
    if (completion.completedById != myUserId) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(
        content: Text('Only the person who logged it can undo.'),
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
        showCloseIcon: true,
        content: Text('Could not undo: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completion = existingCompletion;
    final isDone = completion != null;

    final timeText = isDone
        ? TimeOfDay.fromDateTime(completion.completedAt).format(context)
        : chore.rule.timeOfDay.format(context);
    final scheduleLine = chore.rule.humanLabel();

    return Card(
      color: isDone ? Colors.green.shade50 : scheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => isDone
            ? _undo(context, ref, completion)
            : _log(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isDone
                    ? Colors.green.shade100
                    : scheme.surfaceContainerHighest,
                foregroundColor: isDone
                    ? Colors.green.shade900
                    : scheme.onSurfaceVariant,
                child: Icon(
                  isDone ? Icons.check : Icons.schedule,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chore.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scheduleLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDone
                      ? Colors.green.shade900
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
