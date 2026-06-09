import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chores_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/empty_state.dart';
import '../home/subject_hero_card.dart';

/// Subjects tab — a grid of every subject in the current household with a
/// quick-status line. Tap any tile to dive into its detail screen.
class SubjectsTabScreen extends ConsumerWidget {
  const SubjectsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
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
                child: Text('Could not load friends: $e'),
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
                      title: 'No friends yet',
                      message: 'The + button below adds your first one.',
                      actionLabel: 'Add a friend',
                      onAction: () => context.push(Routes.subjectNew),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = subjects[i];
                return SubjectHeroCard(
                  subject: s,
                  onTap: () => context.push(Routes.subjectDetail(s.id)),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
