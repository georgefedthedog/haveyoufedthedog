import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chores_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/pictures.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/empty_state.dart';
import '../history/leaderboard.dart';
import '../household/picture_artwork.dart';
import 'household_members_row.dart';
import 'subject_hero_card.dart';

/// Home screen — list of subject hero cards for the current household.
/// Phase A redesign: hamburger (app menu) top-left, profile avatar
/// top-right.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCurrent = ref.watch(currentHouseholdControllerProvider);
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    final householdName =
        asyncCurrent.valueOrNull?.name ?? 'Have You Fed The Dog?';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(householdName),
      ),
      body: Column(
        children: [
          if (asyncCurrent.valueOrNull != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push(
                Routes.householdDetails(asyncCurrent.value!.id),
              ),
              child: PictureArtwork(
                picture:
                    PictureRegistry.lookup(asyncCurrent.value!.picture),
                height: 220,
              ),
            ),
            const SizedBox(height: 8),
            HouseholdMembersRow(householdId: asyncCurrent.value!.id),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.read(subjectsControllerProvider.notifier).refresh(),
                  ref.read(choresControllerProvider.notifier).refresh(),
                  ref
                      .read(todayCompletionsControllerProvider.notifier)
                      .refresh(),
                ]);
              },
              child: asyncSubjects.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
                            character: CharacterRegistry.dog,
                            title: 'No characters yet',
                            message:
                                'Add a dog, cat, plant, or whatever else '
                                'needs looking after.',
                            actionLabel: 'Add a subject',
                            onAction: () =>
                                context.push(Routes.subjectNew),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      for (final s in subjects) ...[
                        SubjectHeroCard(
                          subject: s,
                          onTap: () =>
                              context.push(Routes.subjectDetail(s.id)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 16),
                      if (asyncCurrent.valueOrNull != null)
                        Leaderboard(
                          householdId: asyncCurrent.value!.id,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // FAB now lives on the bottom-nav shell, central-docked over the
      // notch — handled by `RootNavShell`.
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
