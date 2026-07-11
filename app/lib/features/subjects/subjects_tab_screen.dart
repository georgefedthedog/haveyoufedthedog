import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chores_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../l10n/l10n.dart';
import '../../router/routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_title.dart';
import '../home/subject_hero_card.dart';

/// Subjects tab - a grid of every subject in the current household with a
/// quick-status line. Tap any tile to dive into its detail screen.
class SubjectsTabScreen extends ConsumerWidget {
  const SubjectsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    // Title lives inside the scroll views (PageTitle) so it scrolls out
    // of the way instead of content sliding under a fixed bar.
    final title = PageTitle(
      text: context.l10n.subjectsTabTitle,
      subtitle: context.l10n.subjectsTabSubtitle,
    );

    // Status-bar inset as scroll padding, not SafeArea: content starts
    // below the status bar but scrolls clean to the physical top edge
    // instead of clipping at the inset line.
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
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
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 0),
            children: [
              title,
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.subjectsLoadFailed('$e')),
              ),
            ],
          ),
          data: (subjects) {
            if (subjects.isEmpty) {
              return ListView(
                padding: EdgeInsets.fromLTRB(16, topInset, 16, 0),
                children: [
                  title,
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyState(
                      character: CharacterRegistry.cat,
                      title: context.l10n.subjectsEmptyTitle,
                      message: context.l10n.subjectsEmptyBody,
                      actionLabel: context.l10n.subjectsAddThing,
                      actionIcon: Icons.pets,
                      onAction: () => context.push(Routes.subjectNew),
                    ),
                  ),
                ],
              );
            }
            // Index 0 is the in-page title, last index is the add
            // button; subjects sit in between.
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 96),
              itemCount: subjects.length + 2,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) return title;
                if (i == subjects.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: () => context.push(Routes.subjectNew),
                        icon: const Icon(Icons.pets),
                        label: Text(context.l10n.subjectsAddThing),
                      ),
                    ),
                  );
                }
                final s = subjects[i - 1];
                return SubjectHeroCard(
                  subject: s,
                  onTap: () => context.push(Routes.subjectDetail(s.id)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
