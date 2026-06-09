import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/character_message.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../chores/chore_row.dart';
import 'completion_tile.dart';

/// Subject detail — a large character hero up top, status message, today's
/// chores as wide rows, all chores, recent history.
class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    return asyncSubjects.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (subjects) {
        Subject? subject;
        for (final s in subjects) {
          if (s.id == subjectId) {
            subject = s;
            break;
          }
        }
        if (subject == null) {
          // Subject got deleted underneath us (or we deep-linked to a
          // stale id). Bounce to home rather than dead-end. Use a
          // post-frame callback so we don't navigate during a build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(Routes.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _Body(subject: subject);
      },
    );
  }
}

class _Body extends ConsumerWidget {
  final Subject subject;
  const _Body({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit subject',
            onPressed: () => context.push(Routes.subjectEdit(subject.id)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(choresControllerProvider.notifier).refresh(),
            ref.read(todayCompletionsControllerProvider.notifier).refresh(),
            ref
                .read(recentCompletionsControllerProvider(subject.id).notifier)
                .refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          children: [
            _Hero(subject: subject),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _TodaySection(subject: subject),
                  const SizedBox(height: 24),
                  _ChoresSection(subjectId: subject.id),
                  const SizedBox(height: 24),
                  _HistorySection(subject: subject),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

class _Hero extends ConsumerWidget {
  final Subject subject;
  const _Hero({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = CharacterRegistry.lookup(subject.icon);
    final theme = Theme.of(context);
    final mood = _moodFor(ref, subject);
    final message = characterMessage(
      character: character,
      mood: mood,
      subjectName: subject.name,
    );

    final streak = ref.watch(subjectStreakProvider(subject.id));

    return Container(
      color: character.stageColor,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CharacterArtwork(
              character: character,
              expression: switch (mood) {
                SubjectMood.allDone => CharacterExpression.happy,
                SubjectMood.pendingSome => CharacterExpression.waiting,
                SubjectMood.none => CharacterExpression.idle,
              },
              stage: false,
              iconSize: 140,
            ),
          ),
          if (streak >= 3) ...[
            const SizedBox(height: 8),
            _StreakPill(streak: streak),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int streak;
  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.streakOrangeSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streak-day streak',
            style: const TextStyle(
              color: AppColors.streakOrange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

SubjectMood _moodFor(WidgetRef ref, Subject subject) {
  final allChores = ref.watch(choresControllerProvider).valueOrNull ?? const [];
  final completions =
      ref.watch(todayCompletionsControllerProvider).valueOrNull ?? const [];

  final now = DateTime.now();
  final dueToday = allChores
      .where((c) => c.subjectId == subject.id && c.rule.isDueOn(now))
      .toList();
  if (dueToday.isEmpty) return SubjectMood.none;

  final doneIds = <String>{
    for (final c in completions)
      if (c.choreId != null) c.choreId!,
  };
  final allDone = dueToday.every((c) => doneIds.contains(c.id));
  return allDone ? SubjectMood.allDone : SubjectMood.pendingSome;
}

class _TodaySection extends ConsumerWidget {
  final Subject subject;
  const _TodaySection({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChores = ref.watch(choresControllerProvider);
    final asyncCompletions = ref.watch(todayCompletionsControllerProvider);

    final today = DateTime.now();
    final allChores = asyncChores.valueOrNull ?? const <Chore>[];
    final dueToday = allChores
        .where((c) => c.subjectId == subject.id && c.rule.isDueOn(today))
        .toList()
      ..sort((a, b) =>
          (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    final completions = asyncCompletions.valueOrNull;
    final latestByChoreId = <String, Completion>{};
    if (completions != null) {
      for (final c in completions) {
        final id = c.choreId;
        if (id != null) latestByChoreId.putIfAbsent(id, () => c);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Today', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 12),
        if (dueToday.isEmpty)
          Text(
            'Nothing due today.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final c in dueToday)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoreRow(
                chore: c,
                subjectId: subject.id,
                existingCompletion: latestByChoreId[c.id],
              ),
            ),
      ],
    );
  }
}

class _ChoresSection extends ConsumerWidget {
  final String subjectId;
  const _ChoresSection({required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChores = ref.watch(choresControllerProvider);
    final chores = (asyncChores.valueOrNull ?? const [])
        .where((c) => c.subjectId == subjectId)
        .toList()
      ..sort((a, b) =>
          (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Schedule', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 12),
        if (chores.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No chores yet.', textAlign: TextAlign.center),
          )
        else
          for (final c in chores)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(c.name),
                  subtitle: Text(c.rule.humanLabel()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.choreEdit(c.id)),
                ),
              ),
            ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add chore'),
          onPressed: () => context.push(Routes.choreNew(subjectId)),
        ),
      ],
    );
  }
}

class _HistorySection extends ConsumerWidget {
  final Subject subject;
  const _HistorySection({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecent =
        ref.watch(recentCompletionsControllerProvider(subject.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent activity',
                  style:
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
            ),
            TextButton(
              onPressed: () =>
                  context.go('${Routes.historyTab}?subject=${subject.id}'),
              child: const Text('See all →'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        asyncRecent.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Could not load history: $e'),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No completions logged yet.',
                    textAlign: TextAlign.center),
              );
            }
            return Column(
              children: [
                for (final c in list.take(5))
                  CompletionTile(
                    completion: c,
                    householdId: subject.householdId,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
