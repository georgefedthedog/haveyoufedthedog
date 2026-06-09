import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/empty_state.dart';

/// Subjects tab — a grid of every subject in the current household with a
/// quick-status line. Tap any tile to dive into its detail screen.
class SubjectsTabScreen extends ConsumerWidget {
  const SubjectsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(subjectsControllerProvider.notifier).refresh(),
            ref.read(choresControllerProvider.notifier).refresh(),
            ref.read(todayCompletionsControllerProvider.notifier).refresh(),
          ]);
        },
        child: asyncSubjects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load subjects: $e'),
              ),
            ],
          ),
          data: (subjects) {
            if (subjects.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyState(
                      character: CharacterRegistry.cat,
                      title: 'No characters yet',
                      message: 'The + button below adds your first one.',
                      actionLabel: 'Add a subject',
                      onAction: () => context.push(Routes.subjectNew),
                    ),
                  ),
                ],
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, i) => _SubjectTile(subject: subjects[i]),
            );
          },
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

class _SubjectTile extends ConsumerWidget {
  final Subject subject;
  const _SubjectTile({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final character = CharacterRegistry.lookup(subject.icon);

    final allChores =
        ref.watch(choresControllerProvider).valueOrNull ?? const <Chore>[];
    final mineToday = allChores
        .where(
          (c) => c.subjectId == subject.id && c.rule.isDueOn(DateTime.now()),
        )
        .toList();
    final hasAnyChores = allChores.any((c) => c.subjectId == subject.id);

    final completions =
        ref.watch(todayCompletionsControllerProvider).valueOrNull ?? const [];
    final doneIds = <String>{
      for (final c in completions)
        if (c.choreId != null) c.choreId!,
    };
    final doneCount = mineToday.where((c) => doneIds.contains(c.id)).length;
    final total = mineToday.length;
    final streak = ref.watch(subjectStreakProvider(subject.id));

    final statusLine = total == 0
        ? (hasAnyChores ? 'Nothing due today' : 'No chores yet')
        : '$doneCount / $total today';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.subjectDetail(subject.id)),
        child: Column(
          children: [
            // Top half: character stage.
            Expanded(
              flex: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: character.stageColor),
                child: CharacterArtwork(
                  character: character,
                  stage: false,
                  iconSize: 56,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (streak >= 3)
                          Text(
                            '🔥$streak',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
