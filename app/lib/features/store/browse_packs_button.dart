import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/household/current_household_controller.dart';
import '../../router/routes.dart';

/// A "Get more packs" link that deep-links to the store. Placed below the
/// picture / character / avatar carousels so buyers discover purchasable art
/// right where they pick it.
///
/// Renders nothing when there's no current household, since a purchase has to
/// be applied to one (the picker screens are reachable in that state).
class BrowsePacksButton extends ConsumerWidget {
  const BrowsePacksButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHousehold =
        ref.watch(currentHouseholdControllerProvider).valueOrNull != null;
    if (!hasHousehold) return const SizedBox.shrink();

    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.palette_outlined),
        label: const Text('Visit the art gallery'),
        onPressed: () => context.push(Routes.store),
      ),
    );
  }
}
