import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/household/current_household_controller.dart';
import '../../core/household/households_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';

/// Lists the user's households and offers Create / Join affordances. Reached
/// either forcibly (2+ households and no persisted current) or voluntarily
/// (from the home screen's "switch household" button).
class HouseholdPickerScreen extends ConsumerWidget {
  const HouseholdPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHouseholds = ref.watch(householdsControllerProvider);
    final currentId = ref
        .watch(currentHouseholdControllerProvider)
        .valueOrNull
        ?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your households'),
        // Manual back arrow because the auto-detected one disappears if the
        // user is force-redirected here (no back stack). Always fall through
        // to home so they can never get stranded.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.home),
        ),
      ),
      body: asyncHouseholds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (households) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (households.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  "You're not in any households yet. Create one or join "
                  'with an invite code below.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final h in households)
              Card(
                child: ListTile(
                  leading: h.id == currentId
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined),
                  title: Text(h.name),
                  subtitle: Text(h.role),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'View / edit',
                    onPressed: () =>
                        context.push(Routes.householdDetails(h.id)),
                  ),
                  onTap: () async {
                    await ref
                        .read(currentHouseholdControllerProvider.notifier)
                        .setCurrent(h.id);
                    if (context.mounted) context.go(Routes.home);
                  },
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add_home),
              label: const Text('Create a new household'),
              onPressed: () => context.push(Routes.householdCreate),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text('Join with invite code'),
              onPressed: () => context.push(Routes.householdJoin),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
