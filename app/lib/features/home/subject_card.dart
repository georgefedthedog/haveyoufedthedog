import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/completion_actions.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_icons.dart';
import 'chore_status_chip.dart';

/// One row in the subjects list on the home screen. Renders the subject's
/// icon + name + today's progress, and a chip per chore that's due today.
/// Chip tap toggles between logged / not-logged.
class SubjectCard extends ConsumerWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.subject, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChores = ref.watch(choresControllerProvider);
    final asyncCompletions = ref.watch(todayCompletionsControllerProvider);

    final today = DateTime.now();
    final allChores = asyncChores.valueOrNull ?? const <Chore>[];
    final hasAnyChores = allChores.any((c) => c.subjectId == subject.id);
    final dueToday = allChores
        .where((c) => c.subjectId == subject.id && c.rule.isDueOn(today))
        .toList();

    // Map each completed chore id to its most-recent completion (the
    // controller already sorts by `-completed_at`, so first-wins is newest).
    final completions = asyncCompletions.valueOrNull;
    final latestByChoreId = <String, Completion>{};
    if (completions != null) {
      for (final c in completions) {
        final id = c.choreId;
        if (id != null) latestByChoreId.putIfAbsent(id, () => c);
      }
    }

    final doneCount =
        dueToday.where((c) => latestByChoreId[c.id] != null).length;
    final allDone = dueToday.isNotEmpty && doneCount == dueToday.length;
    final subtitle = dueToday.isEmpty
        ? (hasAnyChores ? 'Nothing due today' : 'No chores yet')
        : '$doneCount of ${dueToday.length} done today';

    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: allDone
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    child: Icon(
                      SubjectIcons.iconFor(subject.icon),
                      color: allDone
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (subject.nfcTagId != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.nfc,
                          size: 18, color: scheme.onSurfaceVariant),
                    ),
                  if (allDone)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle,
                          color: scheme.primary, size: 28),
                    ),
                ],
              ),
              if (dueToday.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in dueToday)
                      _ChipWithTap(
                        chore: c,
                        subjectId: subject.id,
                        existingCompletion: latestByChoreId[c.id],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

/// Wraps [ChoreStatusChip] with toggle-to-log behaviour. Lives here rather
/// than inside the chip so the chip stays presentational and reusable.
///
/// Tapping an outstanding chip logs a completion; tapping a completed chip
/// undoes the most recent completion of that chore. Either way the UI
/// rebuilds once the invalidation refetches.
class _ChipWithTap extends ConsumerWidget {
  final Chore chore;
  final String subjectId;
  final Completion? existingCompletion;

  const _ChipWithTap({
    required this.chore,
    required this.subjectId,
    required this.existingCompletion,
  });

  Future<void> _log(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final completion = await ref.read(completionActionsProvider).logChore(
            subjectId: subjectId,
            choreId: chore.id,
            source: CompletionSource.button,
          );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Logged: ${chore.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(completionActionsProvider).undo(completion.id),
        ),
      ));
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
