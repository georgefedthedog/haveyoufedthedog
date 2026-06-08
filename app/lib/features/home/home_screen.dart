import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/empty_state.dart';
import 'subject_card.dart';

/// Home screen — read-only list of the current household's subjects.
/// Step 7 will add chore-status chips on each card; Step 8 makes them
/// tappable to log a completion.
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
        title: Text(householdName),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch household',
            onPressed: () => context.push(Routes.householdPicker),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out (temporary)',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
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
              // ListView needed so RefreshIndicator still works on empty.
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyState(
                      icon: Icons.pets,
                      title: 'No subjects yet',
                      message:
                          'Add a dog, cat, plant, or whatever else needs '
                          'looking after.',
                      actionLabel: 'Add a subject',
                      onAction: () => context.push(Routes.subjectNew),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, i) {
                final s = subjects[i];
                return SubjectCard(
                  subject: s,
                  onTap: () => context.push(Routes.subjectDetail(s.id)),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: asyncSubjects.maybeWhen(
        data: (subjects) => subjects.isEmpty
            ? null // Empty state already has its own CTA.
            : FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text('Subject'),
                onPressed: () => context.push(Routes.subjectNew),
              ),
        orElse: () => null,
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
