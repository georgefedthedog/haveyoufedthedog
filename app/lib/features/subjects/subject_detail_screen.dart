import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_icons.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../chores/chore_chip_with_tap.dart';
import 'completion_tile.dart';

/// View one subject — header, today's chips, list of all chores, and
/// recent completions history.
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
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This subject no longer exists.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            bottomNavigationBar: const SafeArea(child: BuildLabel()),
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
          padding: const EdgeInsets.all(16),
          children: [
            _Header(subject: subject),
            const SizedBox(height: 24),
            _TodaySection(subject: subject),
            const SizedBox(height: 24),
            _ChoresSection(subjectId: subject.id),
            const SizedBox(height: 24),
            _HistorySection(subject: subject),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

class _Header extends StatelessWidget {
  final Subject subject;
  const _Header({required this.subject});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: scheme.surfaceContainerHighest,
          child: Icon(
            SubjectIcons.iconFor(subject.icon),
            color: scheme.onSurfaceVariant,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              if (subject.nfcTagId != null)
                Row(
                  children: [
                    Icon(Icons.nfc,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('NFC tag registered',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
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
      ..sort((a, b) => (a.hour * 60 + a.minute)
          .compareTo(b.hour * 60 + b.minute));

    final completions = asyncCompletions.valueOrNull;
    final latestByChoreId = <String, Completion>{};
    if (completions != null) {
      for (final c in completions) {
        final id = c.choreId;
        if (id != null) latestByChoreId.putIfAbsent(id, () => c);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (dueToday.isEmpty)
          Text(
            'Nothing due today.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in dueToday)
                ChoreChipWithTap(
                  chore: c,
                  subjectId: subject.id,
                  existingCompletion: latestByChoreId[c.id],
                ),
            ],
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
      ..sort((a, b) => (a.hour * 60 + a.minute)
          .compareTo(b.hour * 60 + b.minute));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Chores', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (chores.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No chores yet.', textAlign: TextAlign.center),
          )
        else
          for (final c in chores)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(c.name),
                subtitle: Text(c.rule.humanLabel()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.choreEdit(c.id)),
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
        Text('History', style: Theme.of(context).textTheme.titleMedium),
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
                for (final c in list)
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
