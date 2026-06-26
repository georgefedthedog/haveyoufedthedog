import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/completions/stats_controller.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/profile/avatar.dart';
import '../profile/avatar_artwork.dart';

/// Renders the current week's per-member completion counts as a podium for
/// the top 3 + a list for everyone else. Resolves display names via
/// [householdMembersControllerProvider].
class Leaderboard extends ConsumerWidget {
  final String householdId;

  /// When true, hide the header - useful when this is being embedded under
  /// an existing "Leaderboard" title on the host screen.
  final bool dense;

  const Leaderboard({super.key, required this.householdId, this.dense = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(currentWeekStatsProvider);
    final asyncMembers = ref.watch(
      householdMembersControllerProvider(householdId),
    );
    final myUserId = ref.watch(authControllerProvider).valueOrNull?.userId;
    final scheme = Theme.of(context).colorScheme;

    if (stats.perUser.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 28,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No chores completed yet this week!',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final members = asyncMembers.valueOrNull ?? const <HouseholdMember>[];
    final memberByUserId = <String, HouseholdMember>{
      for (final m in members) m.userId: m,
    };

    final entries = stats.perUser.entries.toList();
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    String nameFor(String userId) {
      final m = memberByUserId[userId];
      if (m == null) return 'Someone';
      return userId == myUserId ? '${m.displayName} (you)' : m.displayName;
    }

    final catalog = ref.watch(catalogProvider);
    Avatar? avatarFor(String userId) =>
        catalog.lookupAvatar(memberByUserId[userId]?.avatar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!dense) ...[
          Text(
            'This week',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                _Podium(entries: top3, nameOf: nameFor, avatarOf: avatarFor),
                if (rest.isNotEmpty) ...[
                  const Divider(),
                  for (var i = 0; i < rest.length; i++)
                    ListTile(
                      dense: true,
                      leading: AvatarArtwork(
                        avatar: avatarFor(rest[i].key),
                        size: 32,
                      ),
                      title: Text('${i + 4}. ${nameFor(rest[i].key)}'),
                      trailing: Text(
                        '${rest[i].value}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final String Function(String userId) nameOf;
  final Avatar? Function(String userId) avatarOf;
  const _Podium({
    required this.entries,
    required this.nameOf,
    required this.avatarOf,
  });

  @override
  Widget build(BuildContext context) {
    // Visual order: 2nd, 1st, 3rd (centre wins).
    final positions = <_PodiumSlot>[
      if (entries.length >= 2)
        _PodiumSlot(rank: 2, userId: entries[1].key, score: entries[1].value)
      else
        _PodiumSlot.empty(2),
      _PodiumSlot(rank: 1, userId: entries[0].key, score: entries[0].value),
      if (entries.length >= 3)
        _PodiumSlot(rank: 3, userId: entries[2].key, score: entries[2].value)
      else
        _PodiumSlot.empty(3),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: positions
          .map(
            (p) => Expanded(
              child: _PodiumColumn(slot: p, nameOf: nameOf, avatarOf: avatarOf),
            ),
          )
          .toList(),
    );
  }
}

class _PodiumSlot {
  final int rank;
  final String? userId;
  final int score;
  const _PodiumSlot({
    required this.rank,
    required this.userId,
    required this.score,
  });
  const _PodiumSlot.empty(this.rank) : userId = null, score = 0;
}

class _PodiumColumn extends StatelessWidget {
  final _PodiumSlot slot;
  final String Function(String userId) nameOf;
  final Avatar? Function(String userId) avatarOf;
  const _PodiumColumn({
    required this.slot,
    required this.nameOf,
    required this.avatarOf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final heights = {1: 84.0, 2: 64.0, 3: 48.0};
    // 2nd/3rd blend a touch of ink into the highest surface tone so the
    // blocks still read against the card in light mode (the cream-on-white
    // pairing was nearly invisible).
    final runnerUp = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.06),
      scheme.surfaceContainerHighest,
    );
    final colors = {1: scheme.primaryContainer, 2: runnerUp, 3: runnerUp};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    // 1st gets the spotlight (2× base), 2nd a clear bump (1.5×), 3rd stays
    // at the base - visually echoes the podium block heights below.
    final avatarSizes = {1: 88.0, 2: 66.0, 3: 44.0};
    final avatar = slot.userId == null ? null : avatarOf(slot.userId!);

    // First place gets laurel sprigs hugging the avatar - the asset is a
    // single branch curving up-left (concave side right), so it sits on
    // the left as-is and mirrors for the right.
    Widget avatarArt = AvatarArtwork(
      avatar: avatar,
      size: avatarSizes[slot.rank]!,
    );
    if (slot.rank == 1) {
      // Overlaid, not in a Row - the podium column is too narrow to give
      // the sprigs their own layout width, so they paint outside the
      // avatar's bounds instead (Clip.none) and tuck behind it.
      final sprig = Image.asset(
        'assets/awards/wreath.png',
        height: 70,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
      avatarArt = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(left: -26, top: 14, child: sprig),
          Positioned(
            right: -26,
            top: 14,
            child: Transform.flip(flipX: true, child: sprig),
          ),
          avatarArt,
        ],
      );
    }

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatarArt,
        const SizedBox(height: 4),
        Text(
          slot.userId == null ? '-' : nameOf(slot.userId!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: heights[slot.rank],
              decoration: BoxDecoration(
                color: colors[slot.rank],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  '${slot.score}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: slot.rank == 1
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
            // Medal perched on the podium block's top-right corner.
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                medals[slot.rank]!,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: column,
    );
  }
}
