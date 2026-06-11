import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/completions/awards_controller.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/profile/avatars.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../profile/avatar_artwork.dart';

/// This week's full awards spread: household achievements, the
/// character-voiced subject awards, and the per-member personality
/// awards. Everything derives from [weeklyAwardsProvider]; awards with
/// no winner render in a muted "no winner yet" state so the family can
/// see what's up for grabs.
class AwardsSection extends ConsumerWidget {
  final String householdId;

  const AwardsSection({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awards = ref.watch(weeklyAwardsProvider);
    final members = ref
            .watch(householdMembersControllerProvider(householdId))
            .valueOrNull ??
        const <HouseholdMember>[];
    final memberById = <String, HouseholdMember>{
      for (final m in members) m.userId: m,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Character-voiced awards, one per subject.
        for (final award in awards.characterAwards) ...[
          _CharacterAwardCard(
            award: award,
            winner: award.winnerUserId == null
                ? null
                : memberById[award.winnerUserId],
          ),
          const SizedBox(height: 12),
        ],
        // Badges, two to a row, under their own section header. Team
        // Effort leads — the only badge the whole household earns
        // together.
        const SizedBox(height: 8),
        Text(
          'Badges',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...() {
          final cards = <Widget>[
            _TeamEffortCard(
              awarded: awards.teamEffort,
              contributors: [
                for (final id in awards.contributorIds)
                  if (memberById[id] != null) memberById[id]!,
              ],
            ),
            for (final a in awards.memberAwards)
              MemberAwardCard(
                award: a,
                winner: a.winnerUserId == null
                    ? null
                    : memberById[a.winnerUserId],
              ),
          ];
          return [
            for (var i = 0; i < cards.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[i]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i + 1 < cards.length
                          ? cards[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ];
        }(),
      ],
    );
  }
}

/// Team Effort — the household-wide badge. Earned when nobody carries
/// more than half the week's load. The footer shows everyone who chipped
/// in (overlapping avatar stack) rather than a single winner.
class _TeamEffortCard extends StatelessWidget {
  final bool awarded;
  final List<HouseholdMember> contributors;

  const _TeamEffortCard({required this.awarded, required this.contributors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/awards/badge_team_effort.png',
                width: 108,
                height: 108,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('🤝', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Team Effort',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Everyone shares the load — nobody does more than half',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (awarded && contributors.isNotEmpty)
              SizedBox(
                height: 24,
                child: Stack(
                  children: [
                    for (var i = 0; i < contributors.length; i++)
                      Positioned(
                        left: i * 16.0,
                        child: Tooltip(
                          message: contributors[i].displayName,
                          child: AvatarArtwork(
                            avatar: AvatarRegistry.lookup(
                                contributors[i].avatar),
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  CustomPaint(
                    painter: DashedCirclePainter(
                      color:
                          scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    child: const SizedBox(width: 24, height: 24),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Unclaimed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// "Kiko's Best Human 🩵" — the subject's character hands its weekly
/// prize to whoever did the most of its chores.
class _CharacterAwardCard extends StatelessWidget {
  final CharacterAward award;
  final HouseholdMember? winner;

  const _CharacterAwardCard({required this.award, required this.winner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final character = CharacterRegistry.lookup(award.characterId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: ClipOval(
                child: CharacterArtwork(
                  character: character,
                  stage: true,
                  iconSize: 28,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${award.subjectName}'s ${award.title}",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (winner != null)
                    Row(
                      children: [
                        AvatarArtwork(
                          avatar: AvatarRegistry.lookup(winner!.avatar),
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${winner!.displayName} · ${award.count} '
                            '${award.count == 1 ? "chore" : "chores"}',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No winner yet this week',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trophy-cabinet card for one personality award: big badge art up top,
/// centred title + description, then a footer row with the winner
/// (avatar + name + gold-star tally) or a ghosted unclaimed state.
class MemberAwardCard extends StatelessWidget {
  final MemberAward award;
  final HouseholdMember? winner;

  const MemberAwardCard({
    super.key,
    required this.award,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                award.assetPath,
                width: 108,
                height: 108,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  award.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              award.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              award.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (winner != null)
              Row(
                children: [
                  AvatarArtwork(
                    avatar: AvatarRegistry.lookup(winner!.avatar),
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      winner!.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.check_circle,
                      size: 16, color: scheme.tertiary),
                  const SizedBox(width: 3),
                  Text(
                    '${award.value}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  CustomPaint(
                    painter: DashedCirclePainter(
                      color: scheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    child: const SizedBox(width: 24, height: 24),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Unclaimed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
