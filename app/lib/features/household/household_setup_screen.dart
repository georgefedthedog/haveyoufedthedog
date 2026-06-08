import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../widgets/build_label.dart';
import 'create_household_form.dart';
import 'join_household_form.dart';

/// Where new users land after signing up. Two tabs: Create a household, or
/// Join one with an invite code.
class HouseholdSetupScreen extends ConsumerWidget {
  const HouseholdSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Set up a household'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Create'),
              Tab(text: 'Join'),
            ],
          ),
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
        body: const SafeArea(
          child: TabBarView(
            children: [
              CreateHouseholdForm(),
              JoinHouseholdForm(),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(child: BuildLabel()),
      ),
    );
  }
}
