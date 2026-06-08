import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../widgets/build_label.dart';

/// Placeholder for Step 5c. The real create / join UI lands in Step 5d.
class HouseholdSetupScreen extends ConsumerWidget {
  const HouseholdSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up a household'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out (temporary)',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You are not yet a member of any household.\n\n'
            'Step 5d will add Create + Join forms here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
