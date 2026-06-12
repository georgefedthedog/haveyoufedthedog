import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/households_controller.dart';
import '../../router/routes.dart';
import 'picture_artwork.dart';

/// Lists the user's households and offers Create / Join affordances. Reached
/// either forcibly (2+ households and no persisted current) or voluntarily
/// (from the home screen's "switch household" button).
class HouseholdPickerScreen extends ConsumerWidget {
  const HouseholdPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHouseholds = ref.watch(householdsControllerProvider);
    final currentId = ref
        .watch(currentHouseholdControllerProvider)
        .valueOrNull
        ?.id;

    // The menu is an escape hatch (edit profile / log out) for users
    // force-redirected here with zero households - they can't reach the
    // You tab without one. Anyone with a household has the full app for
    // that, so don't render it.
    final isStranded = asyncHouseholds.valueOrNull?.isEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your households'),
        // Manual back arrow because the auto-detected one disappears if the
        // user is force-redirected here (no back stack). Always fall through
        // to home so they can never get stranded.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        actions: [
          if (isStranded)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    context.push(Routes.profile);
                  case 'logout':
                    ref.read(authControllerProvider.notifier).logout();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Edit profile'),
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Log out'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: asyncHouseholds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (households) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (households.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  "You're not in any households yet. Create one or join "
                  'with an invite code below.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final h in households) ...[
              _HouseholdHeroTile(
                household: h,
                isCurrent: h.id == currentId,
                onTap: () async {
                  await ref
                      .read(currentHouseholdControllerProvider.notifier)
                      .setCurrent(h.id);
                  if (context.mounted) context.go(Routes.home);
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add_home),
              label: const Text('Create a new household'),
              onPressed: () => context.push(Routes.householdCreate),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text('Join with invite code'),
              onPressed: () => context.push(Routes.householdJoin),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the household picker, styled to match the home page's
/// `SubjectHeroCard`: same height, corner radius and border treatment,
/// the house picture as a full-bleed panel on the left (cover-cropped
/// like the home hero), name + role in the middle, and a green check
/// vertically centred on the right when this is the active household.
class _HouseholdHeroTile extends ConsumerWidget {
  final Household household;
  final bool isCurrent;
  final VoidCallback onTap;

  const _HouseholdHeroTile({
    required this.household,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      // Light: thin white border lifting the tile off the cream gradient.
      // Dark: the scheme's subtle outline (white glows too hard there).
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: theme.brightness == Brightness.dark
            ? BorderSide(color: scheme.outline)
            : BorderSide(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 132,
          child: Row(
            children: [
              // House scene on the left, edge to edge - cover crops the
              // transparent corners and zooms in, same as the home hero.
              SizedBox(
                width: 132,
                height: double.infinity,
                child: PictureArtwork(
                  picture: ref
                      .watch(catalogProvider)
                      .lookupPicture(household.picture),
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        household.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        household.role,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Active-household check, vertically centred on the tile.
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  isCurrent ? Icons.check_circle : Icons.circle_outlined,
                  size: 28,
                  color: isCurrent
                      ? Colors.green.shade700
                      : scheme.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
