import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/households_controller.dart';
import '../../core/household/pictures.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your households'),
        // Manual back arrow because the auto-detected one disappears if the
        // user is force-redirected here (no back stack). Always fall through
        // to home so they can never get stranded.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.home),
        ),
        actions: [
          // Escape hatch for users in the forced-picker state (0 households)
          // who need to update their profile or log out.
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

/// One row in the household picker. House picture left, name + role in
/// the middle, a green check on the right when this is the active
/// household. Mirrors the home page's `SubjectHeroCard` layout.
class _HouseholdHeroTile extends StatelessWidget {
  final Household household;
  final bool isCurrent;
  final VoidCallback onTap;

  const _HouseholdHeroTile({
    required this.household,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 110,
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: PictureArtwork(
                    picture: PictureRegistry.lookup(household.picture),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 16),
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
                      const SizedBox(height: 4),
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
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  isCurrent
                      ? Icons.check_circle
                      : Icons.circle_outlined,
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
