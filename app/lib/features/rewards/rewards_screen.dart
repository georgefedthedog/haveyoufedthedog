import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../app/theme.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/completions/reward_streak_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household_actions.dart';
import '../../core/household/picture.dart';
import '../../l10n/l10n.dart';
import '../../router/routes.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../widgets/dashed_rrect_painter.dart';
import '../../widgets/glow_highlight.dart';
import '../household/picture_artwork.dart';
import 'wiggling_present.dart';

/// Which kind of catalog art the rewards page is currently showing. Avatars
/// are excluded - they're personal, not household-scoped, so they aren't
/// streak-claimable.
enum RewardKind {
  character('Characters'),
  picture('Houses');

  const RewardKind(this.label);
  final String label;

  String get wire => this == RewardKind.character ? 'character' : 'picture';
}

/// Free streak-reward claim page. One page for both claimable kinds (toggle
/// at the top): a large "stage" target to focus an item, a tray of earnable
/// art below, a Claim button gated on the household's reward streak, then a
/// "Collected" shelf of what's already been unlocked.
///
/// Reached from the reward-streak bar on the Awards tab. Claiming writes the
/// slug into the household's `unlocked_*` list server-side; the existing
/// pickers then offer it with no changes of their own (the selectable-catalog
/// gate already ORs unlocked slugs in).
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  RewardKind _kind = RewardKind.character;
  String? _focusedSlug;
  bool _busy = false;

  // Anchors the post-claim scroll + glow on the collection card.
  final _collectionKey = GlobalKey<GlowHighlightState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final household = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final threshold = household.rewardStreakThreshold;
    final streak = ref.watch(householdRewardStreakProvider).valueOrNull ?? 0;
    final ready = streak >= threshold;

    // Whether a free reward was already claimed today (its local date).
    final lastRedeem = household.lastFreeRedemption?.toLocal();
    final now = DateTime.now();
    final redeemedToday =
        lastRedeem != null &&
        lastRedeem.year == now.year &&
        lastRedeem.month == now.month &&
        lastRedeem.day == now.day;

    final catalog = ref.watch(catalogProvider);
    final selectable = ref.watch(selectableCatalogProvider);

    // Earnable (the tray) is for the toggled kind only: resolvable catalog
    // art the household can't already select, minus anything flagged
    // reward-excluded (reserved for private/personal packs).
    final selectableCharIds = {for (final c in selectable.characters) c.id};
    final selectablePicIds = {for (final p in selectable.pictures) p.id};
    final earnable = _kind == RewardKind.character
        ? [
            for (final c in catalog.characters)
              if (!c.rewardExcluded && !selectableCharIds.contains(c.id))
                _characterItem(c),
          ]
        : [
            for (final p in catalog.pictures)
              if (!p.rewardExcluded && !selectablePicIds.contains(p.id))
                _pictureItem(p),
          ];

    // The collection shows everything streak-unlocked across *both* kinds,
    // regardless of the toggle.
    final collectedCharSlugs = household.unlockedCharacterIds.toSet();
    final collectedPicSlugs = household.unlockedPictureIds.toSet();
    final collectedChars = [
      for (final c in catalog.characters)
        if (collectedCharSlugs.contains(c.id)) _characterItem(c),
    ];
    final collectedPics = [
      for (final p in catalog.pictures)
        if (collectedPicSlugs.contains(p.id)) _pictureItem(p),
    ];

    // Resolve the focused item, defaulting to the first earnable one.
    _RewardItem? focused;
    for (final it in earnable) {
      if (it.slug == _focusedSlug) {
        focused = it;
        break;
      }
    }
    focused ??= earnable.isEmpty ? null : earnable.first;

    final canClaim = ready && focused != null && !_busy;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.rewardsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ProgressHeader(
                  streak: streak,
                  threshold: threshold,
                  redeemedToday: redeemedToday,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<RewardKind>(
              segments: [
                ButtonSegment(
                  value: RewardKind.character,
                  label: Text(context.l10n.rewardsCharacters),
                  icon: const Icon(Icons.pets),
                ),
                ButtonSegment(
                  value: RewardKind.picture,
                  label: Text(context.l10n.rewardsHouses),
                  icon: const Icon(Icons.home_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _focusedSlug = null;
              }),
            ),
            const SizedBox(height: 24),
            _Stage(
              item: focused,
              square: _kind == RewardKind.character,
              onAccept: (it) => setState(() => _focusedSlug = it.slug),
              onSurprise: earnable.length < 2
                  ? null
                  : () {
                      final pool = [
                        for (final it in earnable)
                          if (it.slug != focused?.slug) it,
                      ];
                      setState(
                        () => _focusedSlug =
                            pool[Random().nextInt(pool.length)].slug,
                      );
                    },
            ),
            const SizedBox(height: 10),
            Text(
              focused?.displayName ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canClaim ? () => _claim(household.id, focused!) : null,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.card_giftcard),
              label: Text(
                !ready
                    ? context.l10n.rewardsStreakToClaim(streak, threshold)
                    : focused == null
                    ? context.l10n.rewardsNothingToClaim
                    : context.l10n.rewardsClaim,
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              _kind == RewardKind.character
                  ? context.l10n.rewardsChooseCharacter
                  : context.l10n.rewardsChooseHouse,
            ),
            const SizedBox(height: 12),
            if (earnable.isEmpty)
              _EmptyNote(context.l10n.rewardsAllUnlocked)
            else
              _Tray(
                items: earnable,
                crossAxisCount: _kind == RewardKind.character ? 4 : 3,
                childAspectRatio: _kind == RewardKind.character
                    ? 1
                    : PictureArtwork.houseAspectRatio,
                focusedSlug: focused?.slug,
                onTap: (slug) => setState(() => _focusedSlug = slug),
              ),
            const SizedBox(height: 28),
            GlowHighlight(
              key: _collectionKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeader(context.l10n.rewardsYourCollection),
                      const SizedBox(height: 12),
                      if (collectedChars.isEmpty && collectedPics.isEmpty)
                        _EmptyNote(context.l10n.rewardsCollectionEmpty)
                      else
                        _CollectedWrap(
                          items: [...collectedChars, ...collectedPics],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(String householdId, _RewardItem item) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final res = await ref
          .read(householdActionsProvider)
          .claimStreakReward(
            householdId: householdId,
            kind: _kind.wire,
            slug: item.slug,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _focusedSlug = null; // refocus onto the next earnable item
      });
      if (res.alreadyUnlocked) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.rewardsAlreadyYours(item.displayName))),
        );
      } else {
        // Confetti splash with the claimed item, then reveal it landing in
        // the collection.
        await _celebrate(item);
        await _revealCollection();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final msg = e is ClientException
          ? (e.response['message'] as String? ?? l10n.rewardsClaimFailed)
          : l10n.rewardsClaimFailed;
      messenger.showSnackBar(SnackBar(showCloseIcon: true, content: Text(msg)));
    }
  }

  /// Full-screen confetti celebration of the just-claimed [item]. Completes
  /// when the splash is dismissed (button, tap, or its auto-timer).
  Future<void> _celebrate(_RewardItem item) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'reward',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => _ClaimCelebration(item: item),
      transitionBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  /// Scrolls the collection card into view and pulses a glow around it, so the
  /// claimed item is visibly "landing" in the collection.
  Future<void> _revealCollection() async {
    final ctx = _collectionKey.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
    if (mounted) _collectionKey.currentState?.flash();
  }

  _RewardItem _characterItem(Character c) => _RewardItem(
    slug: c.id,
    displayName: c.displayName,
    accent: c.stageColor,
    aspectRatio: 1,
    thumb: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: c.stageColor,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: CharacterArtwork(character: c, stage: false),
        ),
      ),
    ),
    hero: CharacterArtwork(character: c, stage: false),
    celebrateHero: CharacterArtwork(
      character: c,
      expression: CharacterExpression.celebrate,
      stage: false,
    ),
  );

  _RewardItem _pictureItem(Picture p) => _RewardItem(
    slug: p.id,
    displayName: p.displayName,
    aspectRatio: 9 / 6,
    thumb: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(
        child: PictureArtwork(picture: p, fit: BoxFit.cover),
      ),
    ),
    hero: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox.expand(
        child: PictureArtwork(picture: p, fit: BoxFit.cover),
      ),
    ),
    celebrateHero: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox.expand(
        child: PictureArtwork(picture: p, fit: BoxFit.cover),
      ),
    ),
  );
}

/// A claimable or collected item, adapted to a common shape so the stage,
/// tray, and shelf don't each branch on kind. [thumb] fills its cell (its
/// [aspectRatio] sets the cell shape - square characters, 9:6 houses); [hero]
/// is the large stage art.
class _RewardItem {
  final String slug;
  final String displayName;

  /// Backdrop for the hero stage (characters sit on their stage colour, like
  /// the tray thumbs; houses fill the panel with their own art, so null).
  final Color? accent;

  /// Width:height of the tray/shelf cell (1 = square character, 9/6 = house).
  final double aspectRatio;
  final Widget thumb;
  final Widget hero;

  /// The art for the claim celebration - a character's celebrate pose; for
  /// houses just the house image (no pose variants).
  final Widget celebrateHero;

  const _RewardItem({
    required this.slug,
    required this.displayName,
    this.accent,
    required this.aspectRatio,
    required this.thumb,
    required this.hero,
    required this.celebrateHero,
  });
}

/// The hero drop target, mirroring the avatar picker's stage: a rounded card
/// (square for characters on their stage colour, a wide panel for houses)
/// that fills + previews the hovered item live while a tray chip drags over
/// it, bounces on settle, and carries a "Surprise me" dice. Shows a muted
/// placeholder when nothing's focused.
class _Stage extends StatefulWidget {
  final _RewardItem? item;
  final bool square;
  final ValueChanged<_RewardItem> onAccept;
  final VoidCallback? onSurprise;

  const _Stage({
    required this.item,
    required this.square,
    required this.onAccept,
    required this.onSurprise,
  });

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with SingleTickerProviderStateMixin {
  static const _size = 184.0;

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final Animation<double> _scale = Tween(
    begin: 0.7,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pop, curve: Curves.elasticOut));

  @override
  void didUpdateWidget(covariant _Stage old) {
    super.didUpdateWidget(old);
    if (widget.item?.slug != old.item?.slug && widget.item != null) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: DragTarget<_RewardItem>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (d) => widget.onAccept(d.data),
        builder: (context, candidate, _) {
          final hovering = candidate.isNotEmpty;
          // Preview the dragged item while it hovers, like the avatar stage.
          final shown = hovering ? candidate.first : widget.item;
          final inner =
              shown?.hero ??
              Icon(
                Icons.card_giftcard_outlined,
                size: 56,
                color: scheme.onSurfaceVariant,
              );

          // Rounded card target with a dashed outline (the signature "drop
          // here" affordance). Characters sit on their stage colour; houses
          // fill with their own art (no accent), so the fill is just the hover
          // tint there. The filled card is inset from the dashed border so the
          // background shows through the gap, like the avatar picker's ring.
          final cardDecoration = BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: hovering
                ? scheme.primaryContainer.withValues(alpha: 0.3)
                : shown?.accent,
          );
          final card = Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: cardDecoration,
              child: Padding(
                // Characters inset further so their stage colour frames the
                // art; houses fill the card (the image is its own frame).
                padding: EdgeInsets.all(widget.square ? 10 : 0),
                child: Center(child: inner),
              ),
            ),
          );
          final framed = widget.square
              ? SizedBox(width: _size, height: _size, child: card)
              : SizedBox(
                  height: _size,
                  child: AspectRatio(
                    aspectRatio: PictureArtwork.houseAspectRatio,
                    child: card,
                  ),
                );
          final stage = CustomPaint(
            foregroundPainter: DashedRRectPainter(
              color: hovering ? scheme.primaryContainer : scheme.outline,
              radius: 20,
              dashLength: 17,
              gapLength: 13,
            ),
            child: framed,
          );

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: hovering ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: ScaleTransition(scale: _scale, child: stage),
              ),
              if (widget.onSurprise != null)
                Positioned(
                  right: -6,
                  bottom: -8,
                  child: Material(
                    color: scheme.secondaryContainer,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      tooltip: context.l10n.avatarSurpriseMe,
                      color: scheme.onSecondaryContainer,
                      icon: const Icon(Icons.casino),
                      onPressed: widget.onSurprise,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Scrollable-into-the-page grid of earnable items. Long-press to drag onto
/// the stage, or tap to focus.
class _Tray extends StatelessWidget {
  final List<_RewardItem> items;
  final int crossAxisCount;
  final double childAspectRatio;
  final String? focusedSlug;
  final ValueChanged<String> onTap;

  const _Tray({
    required this.items,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.focusedSlug,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Bounded, internally-scrolling tray with faded top/bottom edges - the
    // stage stays pinned above while the choices scroll, mirroring the
    // avatar picker.
    return SizedBox(
      height: 260,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.06, 0.94, 1.0],
        ).createShader(bounds),
        child: GridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final it in items)
              _TrayTile(
                item: it,
                selected: it.slug == focusedSlug,
                onTap: () => onTap(it.slug),
              ),
          ],
        ),
      ),
    );
  }
}

/// One earnable tile: tap to focus, long-press to drag onto the stage.
/// Mirrors the app's drag conventions (feedback larger, source ghosted).
class _TrayTile extends StatelessWidget {
  final _RewardItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TrayTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: item.thumb,
      ),
    );

    return LongPressDraggable<_RewardItem>(
      data: item,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: const Offset(-48, -48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            width: 96,
            height: 96 / item.aspectRatio,
            child: item.thumb,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
  }
}

/// Read-only shelf of already-unlocked items, each with a check badge.
/// Characters and houses flow together in a single [Wrap] (fixed height,
/// width following each item's aspect) rather than separate per-kind grids.
class _CollectedWrap extends StatelessWidget {
  final List<_RewardItem> items;

  const _CollectedWrap({required this.items});

  static const _height = 66.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final it in items)
          SizedBox(
            height: _height,
            width: _height * it.aspectRatio,
            child: Stack(
              children: [
                Positioned.fill(child: it.thumb),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: scheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Streak progress toward the next free unlock: a fat bar plus an
/// eligibility line. Shared visual with the Awards-tab StreakRewardBar.
class _ProgressHeader extends StatelessWidget {
  final int streak;
  final int threshold;
  final bool redeemedToday;

  const _ProgressHeader({
    required this.streak,
    required this.threshold,
    required this.redeemedToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ready = streak >= threshold;
    final progress = threshold == 0
        ? 0.0
        : (streak / threshold).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            WigglingPresent(active: ready, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ready
                    ? context.l10n.rewardsClaimYourReward
                    : context.l10n.rewardsYourStreak,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$streak/$threshold',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: ready ? scheme.tertiary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
            color: ready ? scheme.tertiary : scheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          redeemedToday
              ? context.l10n.rewardsRedeemedToday
              : ready
              ? context.l10n.rewardsPickReward
              : context.l10n.rewardsKeepStreak,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        // Up to halfway through the streak, nudge the impatient toward the
        // shop - but not on a day they've already claimed a free one (don't
        // undermine it), and not past halfway (encourage waiting it out).
        if (streak <= threshold / 2 && !redeemedToday) ...[
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(Routes.store),
            child: Text.rich(
              TextSpan(
                text: '${context.l10n.rewardsCantWait} ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: context.l10n.rewardsGetMoreHere,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-screen confetti splash for a freshly-claimed reward - the all-done
/// cup's little sibling. Shows the claimed art popping in under a confetti
/// shower; dismisses on the button, a tap, or a short auto-timer.
class _ClaimCelebration extends StatefulWidget {
  final _RewardItem item;

  const _ClaimCelebration({required this.item});

  @override
  State<_ClaimCelebration> createState() => _ClaimCelebrationState();
}

class _ClaimCelebrationState extends State<_ClaimCelebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _pop;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _pop.forward();
    });
    _autoDismiss = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _confetti.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = widget.item;

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        // Characters celebrate on their own stage colour (houses fall back to
        // the soft violet), mirroring the chore-complete celebration.
        color: item.accent ?? AppColors.violetSoft,
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: const Alignment(0, -0.6),
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: -pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 24,
                  gravity: 0.18,
                  shouldLoop: false,
                  colors: const [
                    Color(0xFF6B4FE0),
                    Color(0xFFF0884A),
                    Color(0xFF4FBF85),
                    Color(0xFFFFC857),
                    Color(0xFFE56B6F),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _pop,
                        curve: Curves.elasticOut,
                      ),
                      child: SizedBox(
                        height: 200,
                        width: 200 * item.aspectRatio,
                        child: item.celebrateHero,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.rewardsUnlockedBang,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onVioletSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.displayName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onVioletSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _dismiss,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                      child: Text(context.l10n.rewardsViewCollection),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
