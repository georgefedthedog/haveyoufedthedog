import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/empty_state.dart';
import 'home_app_bar_avatar.dart';
import 'subject_hero_card.dart';

/// Home screen — list of subject hero cards for the current household.
/// Phase A redesign: hamburger (app menu) top-left, profile avatar
/// top-right. Streak summary card lands in Phase B alongside the streak
/// controller.
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
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onSelected: (value) {
            switch (value) {
              case 'manage':
                final id = asyncCurrent.valueOrNull?.id;
                if (id != null) {
                  context.push(Routes.householdDetails(id));
                }
              case 'switch':
                context.push(Routes.householdPicker);
              case 'logout':
                ref.read(authControllerProvider.notifier).logout();
            }
          },
          itemBuilder: (_) {
            final hasHousehold = asyncCurrent.valueOrNull != null;
            return [
              PopupMenuItem(
                value: 'manage',
                enabled: hasHousehold,
                child: const ListTile(
                  leading: Icon(Icons.home_outlined),
                  title: Text('Manage household'),
                ),
              ),
              const PopupMenuItem(
                value: 'switch',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Switch household'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Log out'),
                ),
              ),
            ];
          },
        ),
        title: Text(householdName),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: HomeAppBarAvatar(),
          ),
        ],
      ),
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
                      character: CharacterRegistry.dog,
                      title: 'No characters yet',
                      message: 'Add a dog, cat, plant, or whatever else '
                          'needs looking after.',
                      actionLabel: 'Get started',
                      onAction: () => context.push(Routes.onboarding),
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
      // FAB now lives on the bottom-nav shell, central-docked over the
      // notch — handled by `RootNavShell`.
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
