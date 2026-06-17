import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/profile/avatar.dart';
import '../../router/routes.dart';
import '../../widgets/drop_target_circle.dart';
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
          const PageTitle(text: 'You'),
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
                  label: 'Switch household',
                  baseColor: theme.colorScheme.primary,
                  labelWidth: 110,
                  onDrop: (_) => widget.onSwitchHousehold(),
                  onTap: _wiggle.poke,
                ),
                const SizedBox(height: 16),
                DropTargetCircle<bool>(
                  icon: Icons.logout,
                  label: 'Log out',
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
