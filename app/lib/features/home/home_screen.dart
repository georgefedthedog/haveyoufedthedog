import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household_memberships_controller.dart';
import '../../widgets/build_label.dart';

/// Placeholder home screen. Step 5b shows both the user's memberships and
/// the resolved "current household" so we can verify the persistence logic.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final asyncMemberships = ref.watch(householdMembershipsControllerProvider);
    final asyncCurrent = ref.watch(currentHouseholdControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Have You Fed The Dog?'),
        actions: [
          // TODO(step-2): temporary, remove when proper menu lands.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out (temporary)',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Hi ${auth.displayName ?? auth.email ?? "stranger"} 👋',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text('Current household',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: asyncCurrent.when(
                loading: () => const Text('Resolving…'),
                error: (e, _) => Text('Error: $e'),
                data: (current) => Text(
                  current == null
                      ? '(none — router will send you to setup or picker '
                          'in Step 5c)'
                      : '${current.householdName} (${current.role})',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Your memberships',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          asyncMemberships.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load memberships: $e'),
              ),
            ),
            data: (memberships) {
              if (memberships.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No memberships.'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final m in memberships)
                    Card(
                      child: ListTile(
                        title: Text(m.householdName),
                        subtitle: Text(m.role),
                        // Step 5b: tapping a row switches current. Useful for
                        // testing persistence. Removed in Step 5e when the
                        // proper picker lands.
                        onTap: () => ref
                            .read(currentHouseholdControllerProvider.notifier)
                            .setCurrent(m.householdId),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
