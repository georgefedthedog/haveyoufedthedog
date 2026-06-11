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
        // Per-member personality awards, two to a row, under their own
        // section header.
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
        for (var i = 0; i < awards.memberAwards.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MemberAwardCard(
                    award: awards.memberAwards[i],
                    winner: awards.memberAwards[i].winnerUserId == null
                        ? null
                        : memberById[awards.memberAwards[i].winnerUserId],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < awards.memberAwards.length
                      ? MemberAwardCard(
                          award: awards.memberAwards[i + 1],
                          winner: awards.memberAwards[i + 1].winnerUserId ==
                                  null
                              ? null
                              : memberById[
                                  awards.memberAwards[i + 1].winnerUserId],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The clean-sweeps + team-effort pair, rendered as a two-up row.
/// Lives separately from [AwardsSection] so the screen can group it with
/// the streak / weekly-count stat cards under "Household achievements".
class HouseholdAchievementsRow extends ConsumerWidget {
  const HouseholdAchievementsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awards = ref.watch(weeklyAwardsProvider);
    return Row(
      children: [
        Expanded(
          child: _AchievementCard(
            emoji: '✨',
            asset: 'assets/awards/badge_clean_sweep.png',
            title: 'Clean sweeps',
            value: '${awards.cleanSweeps}',
            subtitle: awards.perfectWeek
                ? 'Perfect week! 🏆'
                : 'days fully done',
            achieved: awards.cleanSweeps > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AchievementCard(
            emoji: '🤝',
            asset: 'assets/awards/badge_team_effort.png',
            title: 'Team effort',
            value: awards.teamEffort ? 'Yes!' : '—',
            subtitle: awards.teamEffort
                ? 'Everyone pitched in'
                : 'Share the load to earn',
            achieved: awards.teamEffort,
          ),
        ),
      ],
    );
  }
}

/// Household achievement stat card — clean sweeps / team effort.
class _AchievementCard extends StatelessWidget {
  final String emoji;

  /// Badge artwork; falls back to [emoji] if the asset fails to load.
  final String asset;
  final String title;
  final String value;
  final String subtitle;
  final bool achieved;

  const _AchievementCard({
    required this.emoji,
    required this.asset,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  asset,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(emoji,
                      style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              // displaySmall stays on the body font (only headline* carry
              // the display face) — matches the Streak / This-week cards.
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: achieved ? scheme.tertiary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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
