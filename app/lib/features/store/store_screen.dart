import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/household_actions.dart';
import '../../core/store/purchase_controller.dart';
import '../../core/store/store_controller.dart';
import '../../core/store/store_product.dart';
import '../../widgets/drop_target_circle.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/wiggle.dart';
import '../rewards/streak_reward_bar.dart';

/// The pack shop. Lists purchasable products (a `catalog_products` row + live
/// store price), each previewing the packs it unlocks. Buying verifies the
/// receipt server-side and applies the packs to the current household; a
/// Restore action re-grants previously-bought packs.
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface purchase outcomes as snackbars as they settle.
    ref.listen(purchaseControllerProvider, (_, next) {
      if (next.phase == PurchasePhase.success ||
          next.phase == PurchasePhase.error) {
        final msg = next.message;
        if (msg != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(showCloseIcon: true, content: Text(msg)));
        }
      }
    });

    final asyncProducts = ref.watch(storeProductsProvider);
    final busy =
        ref.watch(purchaseControllerProvider).phase == PurchasePhase.pending;
    final household = ref.watch(currentHouseholdControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image packs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore purchases',
            onPressed: busy
                ? null
                : () => ref.read(purchaseControllerProvider.notifier).restore(),
          ),
        ],
      ),
      // A short support note, then the purchasable packs, then redeem-a-code,
      // the reward-streak nudge, and finally the household scope note.
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          const _SupportNote(),
          const SizedBox(height: 24),
          ...asyncProducts.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [_Message("Couldn't load the shop.\n$e")],
            data: (products) => products.isEmpty
                ? [const _Message('No packs available yet.\nCheck back soon!')]
                : [
                    for (var i = 0; i < products.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _ProductCard(product: products[i], busy: busy),
                    ],
                  ],
          ),
          if (household != null) ...[
            const SizedBox(height: 24),
            _PackSettings(household: household),
            // Secondary "or earn one free" nudge, below the packs so it
            // doesn't compete with the buy CTAs.
            const SizedBox(height: 24),
            const Card(
              clipBehavior: Clip.antiAlias,
              child: StreakRewardBar(leadingDivider: false),
            ),
            const SizedBox(height: 24),
            _AppliesToNote(householdName: household.name),
          ],
        ],
      ),
    );
  }
}

/// A gentle, looping rain of hearts behind the store content - the same heart
/// particle as the award celebration, but continuous and sparse.
class _HeartRain extends StatefulWidget {
  const _HeartRain();

  @override
  State<_HeartRain> createState() => _HeartRainState();
}

class _HeartRainState extends State<_HeartRain> {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      // Emit from over the me + Kiko avatars on the left of the card.
      alignment: const Alignment(-0.65, 0),
      child: ConfettiWidget(
        confettiController: _confetti,
        blastDirectionality: BlastDirectionality.explosive,
        emissionFrequency: 0.04,
        numberOfParticles: 1,
        maxBlastForce: 6,
        minBlastForce: 2,
        gravity: 0.1,
        particleDrag: 0.05,
        minimumSize: const Size(9, 9),
        maximumSize: const Size(18, 18),
        shouldLoop: true,
        createParticlePath: _heartPath,
        colors: const [Color(0xFFE56B6F), Color(0xFFFF8FA3), Color(0xFFD64550)],
      ),
    );
  }
}

/// Heart-shaped confetti particle - twin of the one in `awards_section.dart`.
Path _heartPath(Size size) {
  final w = size.width, h = size.height;
  final path = Path();
  path.moveTo(w / 2, h * 0.35);
  path.cubicTo(w * 0.2, h * 0.05, -w * 0.2, h * 0.55, w / 2, h);
  path.moveTo(w / 2, h * 0.35);
  path.cubicTo(w * 0.8, h * 0.05, w * 1.2, h * 0.55, w / 2, h);
  return path;
}

/// A short, warm note encouraging a purchase - the app is solo-made and stays
/// ad-free / subscription-free on pack sales. Placed at the top of the store
/// (high-intent surface) where it nudges fence-sitters without interrupting.
class _SupportNote extends StatelessWidget {
  const _SupportNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 52,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Kiko tucked just behind, overlapping me on the right.
                      Positioned(
                        left: 38,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/general/kiko.png',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      ClipOval(
                        child: Image.asset(
                          'assets/general/me.png',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Made by one man and his dog. No ads. No subscriptions. Packs support the app.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Gentle heart rain over the message.
          const Positioned.fill(child: IgnorePointer(child: _HeartRain())),
        ],
      ),
    );
  }
}

/// A small banner clarifying that everything here unlocks for the household
/// the buyer is currently in - purchases, gift codes and streak rewards alike
/// are household-scoped entitlements.
class _AppliesToNote extends StatelessWidget {
  final String householdName;
  const _AppliesToNote({required this.householdName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text:
                    'Packs you buy or redeem and rewards are unlocked for all '
                    'members of ',
                children: [
                  TextSpan(
                    text: householdName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Redeem an image-pack code for the current household, and list the packs
/// it already has. Any member can redeem - codes are gifts, not licences.
///
/// Collapsed to its header row by default - tap to expand.
/// Type the code, then long-press the gift chip (the code shows beneath
/// it) and carry it into the dashed Apply circle - the same drag mechanic
/// the account card uses for switch/log-out. The deliberate gesture *is*
/// the confirmation. The new art appears in the pickers as soon as the
/// catalog refetches (triggered automatically by the in-place pack update).
class _PackSettings extends ConsumerStatefulWidget {
  final Household household;
  const _PackSettings({required this.household});

  @override
  ConsumerState<_PackSettings> createState() => _PackSettingsState();
}

class _PackSettingsState extends ConsumerState<_PackSettings> {
  final _codeCtrl = TextEditingController();
  // Tapping the Apply circle pokes this; the gift chip wiggles to reveal it's
  // dragged onto the target (only when there's actually a code to carry).
  final _wiggle = WiggleController();
  bool _busy = false;
  bool _expanded = false;

  /// Matches the server-side minimum code length (catalog_packs.code
  /// min 4) - below this the gift chip is visibly parked and won't drag.
  bool get _codeReady => _codeCtrl.text.trim().length >= 4;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(householdActionsProvider)
          .redeemPackCode(
            householdId: widget.household.id,
            rawCode: _codeCtrl.text,
          );
      // Unfocus before clearing: with the field still focused, Android's
      // IME can reassert its composing text over a programmatic clear.
      FocusManager.instance.primaryFocus?.unfocus();
      _codeCtrl.clear();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(
            result.alreadyApplied
                ? '${result.name} is already applied.'
                : '${result.name} applied!',
          ),
        ),
      );
    } on ClientException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(
            e.response['message'] as String? ?? 'Could not apply that code',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The thing you drag: a gift badge with the typed code beneath it.
  /// Same chip sizing as the account card (56 resting, 72 in flight).
  /// Greyed and inert until the code reaches 4 characters; while busy it
  /// hosts the spinner instead - no scrim, per the house busy-state rule.
  Widget _giftChipDraggable(ThemeData theme) {
    final scheme = theme.colorScheme;
    final code = _codeCtrl.text.trim().toUpperCase();
    final active = _codeReady && !_busy;

    Widget chip({required double size}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _codeReady
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
            ),
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.card_giftcard,
                    size: size * 0.45,
                    color: _codeReady
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 110,
            child: Text(
              code,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: _codeReady ? null : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final resting = chip(size: 56);
    if (!active) return resting;
    return LongPressDraggable<String>(
      data: code,
      feedback: Material(color: Colors.transparent, child: chip(size: 72)),
      childWhenDragging: Opacity(opacity: 0.3, child: resting),
      child: resting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Names resolve through the catalog; ids whose pack is unknown
    // (disabled / deleted / catalog not loaded yet) are silently skipped.
    final catalog = ref.watch(catalogProvider);
    final appliedNames = [
      for (final id in widget.household.packIds) ?catalog.packName(id),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accordion header - whole row toggles.
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Redeem a code',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Unlock a pack with a gift code',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Applied packs stay visible even when collapsed - the pills
            // are the at-a-glance proof of what this household has.
            if (appliedNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in appliedNames)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'Pack code',
                          child: TextField(
                            controller: _codeCtrl,
                            enabled: !_busy,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'WOOF-2026',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wiggle(
                                controller: _wiggle,
                                child: _giftChipDraggable(theme),
                              ),
                              DropTargetCircle<String>(
                                icon: Icons.redeem,
                                label: 'Apply pack',
                                baseColor: theme.colorScheme.primary,
                                labelWidth: 110,
                                labelMaxLines: 1,
                                enabled: !_busy,
                                onDrop: (_) => _apply(),
                                // Only hint when there's a code to carry -
                                // wiggling the parked chip would mislead.
                                onTap: (_codeReady && !_busy)
                                    ? _wiggle.poke
                                    : null,
                              ),
                            ],
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

class _ProductCard extends ConsumerWidget {
  final StoreProduct product;

  /// Any purchase in flight - disables Buy across all cards.
  final bool busy;

  const _ProductCard({required this.product, required this.busy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalog = ref.watch(catalogProvider);
    final household = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    final householdPacks = household?.packIds ?? const <String>[];

    // Owned once the household already holds every pack this product grants.
    final owned =
        product.packIds.isNotEmpty &&
        product.packIds.every(householdPacks.contains);

    final progress = ref.watch(purchaseControllerProvider);
    final thisPending =
        progress.phase == PurchasePhase.pending && progress.sku == product.sku;

    // Resolvable pack names (enabled packs only) - what the buyer unlocks.
    final includes = [for (final id in product.packIds) ?catalog.packName(id)];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.heroImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: product.heroImage.toString(),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              product.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (includes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in includes)
                    Chip(
                      label: Text(name),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (owned)
              _OwnedPill(scheme: scheme)
            else
              FilledButton.icon(
                icon: thisPending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: Text(thisPending ? 'Working…' : 'Buy  ${product.price}'),
                onPressed: busy
                    ? null
                    : () => ref
                          .read(purchaseControllerProvider.notifier)
                          .buy(product),
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnedPill extends StatelessWidget {
  final ColorScheme scheme;
  const _OwnedPill({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          'Owned',
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
