import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/pictures.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/empty_state.dart';
import '../chores/chore_row.dart';
import '../history/leaderboard.dart';
import '../household/picture_artwork.dart';
import 'household_members_row.dart';

/// Home screen — household picture, members row, today's chores list,
/// and leaderboard. The whole body scrolls as one — the picture is part
/// of the scrollable content, not a fixed header.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCurrent = ref.watch(currentHouseholdControllerProvider);
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    final householdName =
        asyncCurrent.valueOrNull?.name ?? 'Have You Fed The Dog?';

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(householdName)),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(subjectsControllerProvider.notifier).refresh(),
            ref.read(choresControllerProvider.notifier).refresh(),
            ref.read(todayCompletionsControllerProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
          children: [
            if (asyncCurrent.valueOrNull != null) ...[
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context
                      .push(Routes.householdDetails(asyncCurrent.value!.id)),
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: const Alignment(1, 1),
                      children: [
                        PictureArtwork(
                          picture: PictureRegistry.lookup(
                            asyncCurrent.value!.picture,
                          ),
                          height: 220,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              HouseholdMembersRow(householdId: asyncCurrent.value!.id),
              const SizedBox(height: 16),
            ],
            ...asyncSubjects.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load friends: $e'),
                ),
              ],
              data: (subjects) {
                if (subjects.isEmpty) {
                  return [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: EmptyState(
                        character: CharacterRegistry.dog,
                        title: 'No friends yet',
                        message:
                            'Add a dog, cat, plant, or whatever else needs '
                            'looking after.',
                        actionLabel: 'Add a friend',
                        onAction: () => context.push(Routes.subjectNew),
                      ),
                    ),
                  ];
                }
                final allChores =
                    ref.watch(choresControllerProvider).valueOrNull ??
                        const <Chore>[];
                final completions = ref
                        .watch(todayCompletionsControllerProvider)
                        .valueOrNull ??
                    const <Completion>[];
                final tasks = _todaysTasks(
                  subjects: subjects,
                  chores: allChores,
                  completions: completions,
                );
                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (tasks.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Nothing due today 🎉',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        else
                          for (final t in tasks) ...[
                            ChoreRow(
                              chore: t.chore,
                              subjectId: t.subject.id,
                              existingCompletion: t.completion,
                              leading: _CharacterAvatar(
                                subject: t.subject,
                                expression: _expressionFor(t),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        const SizedBox(height: 16),
                        if (asyncCurrent.valueOrNull != null)
                          Leaderboard(householdId: asyncCurrent.value!.id),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
      // FAB now lives on the bottom-nav shell, central-docked over the
      // notch — handled by `RootNavShell`.
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

/// 44×44 circular avatar showing the subject's character on its stage
/// colour. Used as the leading slot on home-screen chore rows. Pass the
/// [expression] that matches the chore's state (happy for done, sad for
/// overdue, idle otherwise).
class _CharacterAvatar extends StatelessWidget {
  final Subject subject;
  final CharacterExpression expression;
  const _CharacterAvatar({
    required this.subject,
    this.expression = CharacterExpression.idle,
  });

  @override
  Widget build(BuildContext context) {
    final character = CharacterRegistry.lookup(subject.icon);
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipOval(
        child: ColoredBox(
          color: character.stageColor,
          child: CharacterArtwork(
            character: character,
            expression: expression,
            stage: false,
            iconSize: 28,
          ),
        ),
      ),
    );
  }
}

/// One row to render: the chore, its subject, and (if logged) the
/// matching completion.
class _TodayTask {
  final Chore chore;
  final Subject subject;
  final Completion? completion;
  const _TodayTask({
    required this.chore,
    required this.subject,
    required this.completion,
  });
}

/// Picks the right character expression for a today-tile:
/// happy when the chore is logged, sad when it's overdue, idle otherwise.
CharacterExpression _expressionFor(_TodayTask t) {
  if (t.completion != null) return CharacterExpression.happy;
  final scheduledAt = t.chore.rule.scheduledAt(DateTime.now());
  if (scheduledAt.isBefore(DateTime.now())) return CharacterExpression.sad;
  return CharacterExpression.idle;
}

/// Builds the sorted list of today's chores across all subjects.
/// Sorted by scheduled time ascending. Pending and done are interleaved
/// in time order.
List<_TodayTask> _todaysTasks({
  required List<Subject> subjects,
  required List<Chore> chores,
  required List<Completion> completions,
}) {
  final now = DateTime.now();
  final subjectById = <String, Subject>{for (final s in subjects) s.id: s};
  final completionByChoreId = <String, Completion>{
    for (final c in completions)
      if (c.choreId != null) c.choreId!: c,
  };

  final out = <_TodayTask>[];
  for (final chore in chores) {
    if (!chore.rule.isDueOn(now)) continue;
    final subject = subjectById[chore.subjectId];
    if (subject == null) continue;
    out.add(_TodayTask(
      chore: chore,
      subject: subject,
      completion: completionByChoreId[chore.id],
    ));
  }
  out.sort((a, b) {
    final ta = a.chore.rule.scheduledAt(now);
    final tb = b.chore.rule.scheduledAt(now);
    return ta.compareTo(tb);
  });
  return out;
}
