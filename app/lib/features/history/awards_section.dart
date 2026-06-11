import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/completions/awards_controller.dart';
import '../../core/subjects/character.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/profile/avatars.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../profile/avatar_artwork.dart';

/// The character-voiced featured awards — one card per subject in a
/// swipeable carousel. Renders nothing when there's nothing to show.
///
/// Pass [onlyWonBy] to filter to awards a specific member holds (the
/// You tab shows just yours).
class FeaturedAwards extends ConsumerWidget {
  final String householdId;
  final String? onlyWonBy;

  const FeaturedAwards({
    super.key,
    required this.householdId,
    this.onlyWonBy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awards = ref.watch(weeklyAwardsProvider);
    final visible = [
      for (final a in awards.characterAwards)
        if (onlyWonBy == null || a.winnerUserId == onlyWonBy) a,
    ];
    if (visible.isEmpty) return const SizedBox.shrink();
    final members = ref
            .watch(householdMembersControllerProvider(householdId))
            .valueOrNull ??
        const <HouseholdMember>[];
    final memberById = <String, HouseholdMember>{
      for (final m in members) m.userId: m,
    };
    return _CharacterAwardCarousel(
      awards: visible,
      memberById: memberById,
    );
  }
}

/// The "Badges" section: header, the household-wide Team Effort card,
/// then the personality awards two to a row. Awards with no winner
/// render in a muted unclaimed state so the family can see what's up
/// for grabs.
class BadgesSection extends ConsumerWidget {
  final String householdId;

  const BadgesSection({super.key, required this.householdId});

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
          winner:
              a.winnerUserId == null ? null : memberById[a.winnerUserId],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Badges',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
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
              child: ColorFiltered(
                colorFilter: awarded
                    ? const ColorFilter.mode(
                        Colors.transparent, BlendMode.dst)
                    : _greyscale,
                child: Image.asset(
                  'assets/awards/badge_team_effort.png',
                  width: 108,
                  height: 108,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Text('🤝', style: TextStyle(fontSize: 48)),
                ),
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

/// Swipeable carousel of featured character awards — one page per
/// subject, with indicator dots when there's more than one.
class _CharacterAwardCarousel extends StatefulWidget {
  final List<CharacterAward> awards;
  final Map<String, HouseholdMember> memberById;

  const _CharacterAwardCarousel({
    required this.awards,
    required this.memberById,
  });

  @override
  State<_CharacterAwardCarousel> createState() =>
      _CharacterAwardCarouselState();
}

class _CharacterAwardCarouselState extends State<_CharacterAwardCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.awards.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final award = widget.awards[i];
              return _FeaturedAwardCard(
                award: award,
                winner: award.winnerUserId == null
                    ? null
                    : widget.memberById[award.winnerUserId],
              );
            },
          ),
        ),
        if (widget.awards.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.awards.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Luminance-preserving greyscale — unclaimed badge art renders washed
/// out until somebody earns it.
const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Heart-shaped confetti particle for the appreciation burst.
Path _heartPath(Size size) {
  final w = size.width, h = size.height;
  final path = Path();
  path.moveTo(w / 2, h * 0.35);
  path.cubicTo(w * 0.2, h * 0.05, -w * 0.2, h * 0.55, w / 2, h);
  path.moveTo(w / 2, h * 0.35);
  path.cubicTo(w * 0.8, h * 0.05, w * 1.2, h * 0.55, w / 2, h);
  return path;
}

/// "Kiko-dog's Best Human 🩵" as a featured-award spread: the character's
/// trophy pose on a lavender panel, a FEATURED AWARD pill, the title,
/// a thank-you line in the character's voice, and the winner. Tapping a
/// winning character bursts hearts — a little thank-you back.
class _FeaturedAwardCard extends ConsumerStatefulWidget {
  final CharacterAward award;
  final HouseholdMember? winner;

  const _FeaturedAwardCard({required this.award, required this.winner});

  @override
  ConsumerState<_FeaturedAwardCard> createState() =>
      _FeaturedAwardCardState();
}

class _FeaturedAwardCardState extends ConsumerState<_FeaturedAwardCard> {
  late final ConfettiController _hearts;

  @override
  void initState() {
    super.initState();
    _hearts = ConfettiController(duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _hearts.dispose();
    super.dispose();
  }

  CharacterAward get award => widget.award;
  HouseholdMember? get winner => widget.winner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = CharacterRegistry.lookup(award.characterId);

    // Poster palette derived from the character's stage colour (same in
    // both themes): pale wash for the card, deeper tone for the circle,
    // a saturated mid-tone for the pill, dark ink of the same hue for
    // the text. Each character gets its own colour story.
    final stageHsl = HSLColor.fromColor(character.stageColor);
    final cardColor = stageHsl
        .withLightness((stageHsl.lightness + 0.03).clamp(0.0, 1.0))
        .toColor();
    final inkColor = stageHsl
        .withSaturation((stageHsl.saturation + 0.15).clamp(0.0, 1.0))
        .withLightness(0.24)
        .toColor();
    final mutedInk = inkColor.withValues(alpha: 0.75);
    final pillColor = stageHsl
        .withSaturation((stageHsl.saturation + 0.25).clamp(0.0, 1.0))
        .withLightness(0.45)
        .toColor();
    final circleLight = stageHsl
        .withLightness((stageHsl.lightness - 0.06).clamp(0.0, 1.0))
        .toColor();
    final circleDark = stageHsl
        .withLightness((stageHsl.lightness - 0.26).clamp(0.0, 1.0))
        .toColor();

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Big trophy pose standing in front of a gradient circle —
            // the character overflows the circle for the poster look.
            // Only the award's winner gets the heart burst on tap — it's
            // the character thanking *their* human.
            GestureDetector(
              onTap: winner != null &&
                      winner!.userId ==
                          ref.watch(authControllerProvider)
                              .valueOrNull
                              ?.userId
                  ? _hearts.play
                  : null,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 165,
                child: Stack(
                  // Anchored below centre (halfway to the bottom) so the
                  // circle and character sit low without touching the edge.
                  alignment: const Alignment(0, 0.5),
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 165,
                      height: 165,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.bottomRight,
                          end: Alignment.topLeft,
                          colors: [circleDark, circleLight],
                        ),
                      ),
                    ),
                    // OverflowBox lets the art render wider than its lane
                    // so it can spill over the circle like a poster.
                    OverflowBox(
                      maxWidth: 250,
                      maxHeight: 250,
                      alignment: const Alignment(0, 0.5),
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        // Trophy pose when won; a sad face while the award
                        // sits unclaimed.
                        child: Image.asset(
                          winner != null
                              ? character.awardAsset
                              : character.assetFor(CharacterExpression.sad),
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, _, _) => CharacterArtwork(
                            character: character,
                            stage: false,
                            iconSize: 64,
                          ),
                        ),
                      ),
                    ),
                    // Heart burst, emitting from the character's middle.
                    Align(
                      alignment: Alignment.center,
                      child: ConfettiWidget(
                        confettiController: _hearts,
                        blastDirectionality:
                            BlastDirectionality.explosive,
                        emissionFrequency: 0.6,
                        numberOfParticles: 6,
                        gravity: 0.1,
                        maxBlastForce: 14,
                        minBlastForce: 5,
                        shouldLoop: false,
                        createParticlePath: _heartPath,
                        minimumSize: const Size(16, 16),
                        maximumSize: const Size(26, 26),
                        colors: const [
                          Color(0xFFE56B6F),
                          Color(0xFFFF8FA3),
                          Color(0xFFD64550),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (winner != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AWARDED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    "${award.subjectName}'s",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: inkColor,
                    ),
                  ),
                  Text(
                    award.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // headlineSmall carries the display font (Knewave).
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: inkColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    winner != null
                        ? (characterAwardThanks[award.characterId] ??
                            characterAwardThanks['generic']!)
                        : 'Up for grabs — do the most of '
                            "${award.subjectName}'s chores to win it!",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedInk,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (winner != null)
                    Row(
                      children: [
                        AvatarArtwork(
                          avatar: AvatarRegistry.lookup(winner!.avatar),
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                winner!.displayName,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: inkColor,
                                ),
                              ),
                              Text(
                                '${award.count} '
                                '${award.count == 1 ? "chore" : "chores"}',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: mutedInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text('🥇', style: TextStyle(fontSize: 24)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        CustomPaint(
                          painter: DashedCirclePainter(
                            color: mutedInk,
                          ),
                          child:
                              const SizedBox(width: 32, height: 32),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unclaimed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
              child: ColorFiltered(
                colorFilter: winner == null
                    ? _greyscale
                    : const ColorFilter.mode(
                        Colors.transparent, BlendMode.dst),
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
