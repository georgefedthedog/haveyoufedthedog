import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household_memberships_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';

/// Placeholder home screen. Step 5 ends here. Step 6 will replace the body
/// with the subjects list.
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
          // TODO(step-5): temporary, replace with proper menu in Step 16.
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
                      ? '(none)'
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
            data: (memberships) => Column(
              children: [
                for (final m in memberships)
                  Card(
                    child: ListTile(
                      title: Text(m.householdName),
                      subtitle: Text(m.role),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
