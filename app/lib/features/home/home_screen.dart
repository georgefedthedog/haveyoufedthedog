import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/household_memberships_controller.dart';
import '../../widgets/build_label.dart';

/// Placeholder home screen. Step 5a shows the user's household memberships
/// as raw text so we can verify the controller works. Steps 5b–5f wire it
/// into routing and the real home UI.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final asyncMemberships = ref.watch(householdMembershipsControllerProvider);

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
          Text(
            'Your households',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                    child: Text(
                      'No households yet — routing will send you to a '
                      'setup screen in Step 5c.',
                    ),
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
