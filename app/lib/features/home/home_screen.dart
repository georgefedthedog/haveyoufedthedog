import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../widgets/build_label.dart';

/// Placeholder home screen for Step 1. Will be replaced when the real home
/// (subjects list) lands in Step 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
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
      body: Center(
        child: Text('Hi ${auth.displayName ?? auth.email ?? "stranger"} 👋'),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
