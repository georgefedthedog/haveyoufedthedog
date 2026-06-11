import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/completions/awards_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/profile/avatar.dart';
import '../../core/profile/avatars.dart';
import '../../router/routes.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../history/awards_section.dart';
import 'avatar_artwork.dart';

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
    final avatar = AvatarRegistry.lookup(auth?.avatar);

    return Scaffold(
      appBar: AppBar(title: const Text('You'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push(Routes.profile),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AvatarArtwork(avatar: avatar, size: 144),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (auth != null) _MyAwardsCard(myUserId: auth.userId),
          const SizedBox(height: 16),
          Text(
            'Moving day?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _AccountActionsCard(
            avatar: avatar,
            name: name.isEmpty ? 'You' : name,
            onSwitchHousehold: () => context.push(Routes.householdPicker),
            onLogout: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

/// Drag-to-act account card, mirroring the household members' drag
/// mechanic: your avatar chip on the left, two dashed drop circles on
/// the right — purple "Switch household" above red "Log out". Long-press
/// the avatar and carry it into a circle. The deliberate gesture *is*
/// the confirmation — no dialog.
class _AccountActionsCard extends StatelessWidget {
  final Avatar? avatar;
  final String name;
  final VoidCallback onSwitchHousehold;
  final VoidCallback onLogout;

  const _AccountActionsCard({
    required this.avatar,
    required this.name,
    required this.onSwitchHousehold,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip({required double size}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarArtwork(avatar: avatar, size: size),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final restingChip = chip(size: 56);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LongPressDraggable<bool>(
              data: true,
              feedback: Material(
                color: Colors.transparent,
                child: chip(size: 72),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: restingChip),
              child: restingChip,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DropCircle(
                  icon: Icons.swap_horiz,
                  label: 'Switch household',
                  baseColor: theme.colorScheme.primary,
                  onDrop: onSwitchHousehold,
                ),
                const SizedBox(height: 16),
                _DropCircle(
                  icon: Icons.logout,
                  label: 'Log out',
                  baseColor: Colors.red.shade300,
                  hoverColor: Colors.red,
                  onDrop: onLogout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One dashed drop circle + caption for the account card. Fills solid
/// (in [hoverColor], defaulting to [baseColor]) while a drag hovers.
class _DropCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color baseColor;
  final Color? hoverColor;
  final VoidCallback onDrop;

  const _DropCircle({
    required this.icon,
    required this.label,
    required this.baseColor,
    this.hoverColor,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<bool>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (_) => onDrop(),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        final color = hovering ? (hoverColor ?? baseColor) : baseColor;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: DashedCirclePainter(color: color, filled: hovering),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  icon,
                  size: 24,
                  color: hovering ? Colors.white : color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 110,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Card listing every weekly award the signed-in user currently holds —
/// the personality awards plus any character-given ones. Quiet "nothing
/// yet" line when the trophy shelf is empty.
class _MyAwardsCard extends ConsumerWidget {
  final String? myUserId;

  const _MyAwardsCard({required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final awards = ref.watch(weeklyAwardsProvider);

    // Me as a HouseholdMember — the badge card footer wants the avatar.
    final hh = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    final members = hh == null
        ? const <HouseholdMember>[]
        : ref.watch(householdMembersControllerProvider(hh.id)).valueOrNull ??
              const <HouseholdMember>[];
    HouseholdMember? me;
    for (final m in members) {
      if (m.userId == myUserId) {
        me = m;
        break;
      }
    }

    final mine = [
      for (final a in awards.memberAwards)
        if (a.winnerUserId == myUserId) a,
    ];
    final mineFromCharacters = [
      for (final a in awards.characterAwards)
        if (a.winnerUserId == myUserId) a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your awards and badges',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (mine.isEmpty && mineFromCharacters.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nothing yet — plenty of week left!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          // Same featured-award carousel as the Awards tab, filtered to
          // the awards this user holds.
          if (mineFromCharacters.isNotEmpty && hh != null) ...[
            FeaturedAwards(householdId: hh.id, onlyWonBy: myUserId),
            const SizedBox(height: 12),
          ],
          // Same trophy-cabinet badge cards as the Awards tab, two-up.
          for (var i = 0; i < mine.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MemberAwardCard(award: mine[i], winner: me),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < mine.length
                        ? MemberAwardCard(award: mine[i + 1], winner: me)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
