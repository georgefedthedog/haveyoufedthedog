import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household_memberships_controller.dart';
import '../../widgets/build_label.dart';

/// Placeholder for Step 5c — minimal list so we can verify routing.
/// The real picker (with proper card UI) lands in Step 5e.
class HouseholdPickerScreen extends ConsumerWidget {
  const HouseholdPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMemberships = ref.watch(householdMembershipsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a household'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out (temporary)',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: asyncMemberships.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (memberships) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final m in memberships)
              Card(
                child: ListTile(
                  title: Text(m.householdName),
                  subtitle: Text(m.role),
                  onTap: () => ref
                      .read(currentHouseholdControllerProvider.notifier)
                      .setCurrent(m.householdId),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
