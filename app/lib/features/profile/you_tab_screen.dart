import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/household/act_as_highlight_controller.dart';
import '../../core/household/acting_user_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/profile/avatar.dart';
import '../../l10n/l10n.dart';
import '../../router/routes.dart';
import '../../widgets/drop_target_circle.dart';
import '../../widgets/glow_highlight.dart';
import '../../widgets/page_title.dart';
import '../../widgets/wiggle.dart';
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
    final avatar = ref.watch(catalogProvider).lookupAvatar(auth?.avatar);

    // Status-bar inset as scroll padding, not SafeArea: content starts
    // below the status bar but scrolls clean to the physical top edge
    // instead of clipping at the inset line.
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 96),
        children: [
          PageTitle(text: context.l10n.youTabTitle),
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
                        AvatarArtwork(avatar: avatar, size: 162),
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
                    name.isEmpty ? context.l10n.youNoName : name,
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
          const _ActAsCard(),
          Text(
            context.l10n.movingDay,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _AccountActionsCard(
            avatar: avatar,
            name: name.isEmpty ? context.l10n.commonYou : name,
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
/// the right - purple "Switch household" above red "Log out". Long-press
/// the avatar and carry it into a circle. The deliberate gesture *is*
/// the confirmation - no dialog.
class _AccountActionsCard extends StatefulWidget {
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
  State<_AccountActionsCard> createState() => _AccountActionsCardState();
}

class _AccountActionsCardState extends State<_AccountActionsCard> {
  // Tapping either drop circle pokes this; the draggable chip wiggles to
  // reveal it can be carried into the targets.
  final _wiggle = WiggleController();

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip({required double size}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarArtwork(avatar: widget.avatar, size: size),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              widget.name,
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
            Wiggle(
              controller: _wiggle,
              child: LongPressDraggable<bool>(
                data: true,
                feedback: Material(
                  color: Colors.transparent,
                  child: chip(size: 72),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: restingChip),
                child: restingChip,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropTargetCircle<bool>(
                  icon: Icons.swap_horiz,
                  label: context.l10n.switchHousehold,
                  baseColor: theme.colorScheme.primary,
                  labelWidth: 110,
                  onDrop: (_) => widget.onSwitchHousehold(),
                  onTap: _wiggle.poke,
                ),
                const SizedBox(height: 16),
                DropTargetCircle<bool>(
                  icon: Icons.logout,
                  label: context.l10n.commonLogOut,
                  baseColor: Colors.red.shade300,
                  hoverColor: Colors.red,
                  labelWidth: 110,
                  onDrop: (_) => widget.onLogout(),
                  onTap: _wiggle.poke,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Act as" picker: lets you log chores as a managed (loginless) member of
/// the current household, on this device. Only managed members can be acted as
/// - real members keep self-only attribution - so the card hides entirely
/// when the household has none. A banner + the You tab's red ring are the cue
/// that you're still acting as someone else.
class _ActAsCard extends ConsumerStatefulWidget {
  const _ActAsCard();

  @override
  ConsumerState<_ActAsCard> createState() => _ActAsCardState();
}

class _ActAsCardState extends ConsumerState<_ActAsCard> {
  /// Pulses a primary glow around the card when the home members row asks us
  /// to highlight (same shared cue as the invite card + rewards collection).
  final _actAsGlowKey = GlobalKey<GlowHighlightState>();

  /// Guards against re-handling the same highlight request across rebuilds.
  bool _handled = false;

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('$e')),
      );
    }
  }

  /// Scroll this card into view and pulse its border. Triggered once when a
  /// pending highlight request lands (after navigating here from the home row).
  void _handleHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(actAsHighlightProvider.notifier).consume();
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        alignment: 0.1,
      );
      _actAsGlowKey.currentState?.flash();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hh = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    if (hh == null) return const SizedBox.shrink();
    final members =
        ref.watch(householdMembersControllerProvider(hh.id)).valueOrNull ??
        const <HouseholdMember>[];
    final managed = members.where((m) => m.isManaged).toList();
    if (managed.isEmpty) return const SizedBox.shrink();

    // Only act on a pending highlight once the card is actually showing (past
    // the early returns). Consuming the flag flips it false, which resets the
    // guard on the next build so a later tap highlights again.
    final wantHighlight = ref.watch(actAsHighlightProvider);
    if (wantHighlight && !_handled) {
      _handled = true;
      _handleHighlight();
    } else if (!wantHighlight) {
      _handled = false;
    }

    final catalog = ref.watch(catalogProvider);
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final myUserId = auth?.userId;
    final actingUserId = ref.watch(actingUserControllerProvider).valueOrNull;
    final actingIsOther = actingUserId != null && actingUserId != myUserId;

    String? actingName;
    if (actingIsOther) {
      for (final m in managed) {
        if (m.userId == actingUserId) {
          actingName = m.displayName;
          break;
        }
      }
    }

    final notifier = ref.read(actingUserControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.whoseTurn,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.whoseTurnSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        GlowHighlight(
          key: _actAsGlowKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (actingIsOther)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.theater_comedy,
                            size: 18,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.actingTurn(
                                actingName ?? context.l10n.commonSomeone,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _run(() => notifier.revertToSelf()),
                            child: Text(context.l10n.myTurnAgain),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _ActAsChip(
                        avatar: catalog.lookupAvatar(auth?.avatar),
                        label: context.l10n.commonYou,
                        selected: !actingIsOther,
                        onTap: () => _run(() => notifier.revertToSelf()),
                      ),
                      for (final m in managed)
                        _ActAsChip(
                          avatar: catalog.lookupAvatar(m.avatar),
                          label: m.displayName,
                          selected: actingUserId == m.userId,
                          onTap: () => _run(() => notifier.setActing(m.userId)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// One avatar in the Act-as picker: tap to switch to that identity. The
/// current one gets a primary selection ring.
class _ActAsChip extends StatelessWidget {
  final Avatar? avatar;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActAsChip({
    required this.avatar,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: AvatarArtwork(avatar: avatar, size: 56),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
