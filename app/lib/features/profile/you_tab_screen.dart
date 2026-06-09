import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';

/// "You" bottom-nav branch: a polished profile + settings landing surface.
/// Edit lives in [EditProfileScreen]; this surface just summarises and
/// hosts the global log-out.
class YouTabScreen extends ConsumerWidget {
  const YouTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = ref.watch(authControllerProvider).valueOrNull;

    final name = auth?.displayName ?? '';
    final email = auth?.email ?? '';
    final initial = name.trim().isEmpty
        ? null
        : name.trim()[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: initial != null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : const Icon(Icons.person_outline, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name.isEmpty ? '(no name set)' : name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                    onPressed: () => context.push(Routes.profile),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Switch household'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.householdPicker),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              iconColor: scheme.error,
              textColor: scheme.error,
              onTap: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
