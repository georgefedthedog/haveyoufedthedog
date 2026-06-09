import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../router/routes.dart';

/// Profile avatar shown in the top-right of the home screen's AppBar.
/// Tap navigates to the profile screen. Renders the signed-in user's
/// first initial when their display name is known; falls back to a
/// silhouette while auth state is loading.
class HomeAppBarAvatar extends ConsumerWidget {
  const HomeAppBarAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    final name = auth?.displayName?.trim();
    final initial =
        (name != null && name.isNotEmpty) ? name[0].toUpperCase() : null;

    return Tooltip(
      message: 'Profile',
      child: InkResponse(
        onTap: () => context.push(Routes.profile),
        radius: 24,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: initial != null
              ? Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                )
              : const Icon(Icons.person_outline, size: 20),
        ),
      ),
    );
  }
}
