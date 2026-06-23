import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/household/act_as_highlight_controller.dart';
import '../../core/household/acting_user_controller.dart';
import '../../core/household/household_members_controller.dart';
import '../../router/routes.dart';
import '../profile/avatar_artwork.dart';

/// Horizontal row of member avatars for a household. Each avatar shows the
/// first letter of the member's display name on a coloured circle, picked
/// deterministically from the user id so the same person gets the same
/// colour everywhere.
class HouseholdMembersRow extends ConsumerWidget {
  final String householdId;

  const HouseholdMembersRow({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMembers = ref.watch(
      householdMembersControllerProvider(householdId),
    );
    final members = asyncMembers.valueOrNull ?? const [];
    if (members.isEmpty) return const SizedBox.shrink();

    // Identity-only watch so profile-data churn (name/avatar saves) doesn't
    // rebuild the row - just whether each avatar is the signed-in user's.
    final currentUserId = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.userId),
    );

    // When acting as a managed member (not yourself), ring that member's
    // avatar in red - the same cue as the You tab's bottom-bar icon.
    final actingMember = ref.watch(actingMemberProvider).valueOrNull;
    final actingAsUserId =
        (actingMember != null && actingMember.userId != currentUserId)
        ? actingMember.userId
        : null;

    return SizedBox(
      height: 56,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < members.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Builder(
                  builder: (_) {
                    final m = members[i];
                    final name = m.displayName;
                    final initial = name.trim().isEmpty
                        ? '?'
                        : name.trim()[0].toUpperCase();
                    return _Avatar(
                      avatarId: m.avatar,
                      initial: initial,
                      seed: m.userId,
                      name: name,
                      isOwner: m.isOwner,
                      isCurrentUser: m.userId == currentUserId,
                      isManaged: m.isManaged,
                      isActingAs: m.userId == actingAsUserId,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends ConsumerWidget {
  /// User's chosen avatar id, or null if they haven't picked one yet.
  /// When non-null we render the matching [AvatarArtwork]; when null we
  /// fall back to the seeded-initial circle so households mid-rollout
  /// still have something personal instead of identical silhouettes.
  final String? avatarId;
  final String initial;
  final String seed;
  final String name;
  final bool isOwner;

  /// True for the signed-in user's own chip - taps deep-link to the You tab
  /// (their profile).
  final bool isCurrentUser;

  /// True for a managed (loginless) member. Any signed-in member can act as
  /// one, so their chip is tappable too and routes to the You tab (where the
  /// "Whose turn?" picker lives). Real members other than you are display-only.
  final bool isManaged;

  /// True when the device is currently acting as this member (and it isn't
  /// you) - draws a red ring to match the You tab's bottom-bar icon.
  final bool isActingAs;

  const _Avatar({
    required this.avatarId,
    required this.initial,
    required this.seed,
    required this.name,
    required this.isOwner,
    required this.isCurrentUser,
    required this.isManaged,
    required this.isActingAs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = ref.watch(catalogProvider).lookupAvatar(avatarId);

    Widget circle;
    if (avatar != null) {
      circle = AvatarArtwork(avatar: avatar, size: 44);
    } else {
      final bg = _colorFromSeed(seed);
      circle = CircleAvatar(
        radius: 22,
        backgroundColor: bg,
        foregroundColor: _readableOn(bg),
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: _readableOn(bg),
          ),
        ),
      );
    }

    if (isActingAs) {
      // Purple ring hugging the avatar to mark who you're acting as.
      circle = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.purple, width: 2),
        ),
        child: circle,
      );
    }

    if (isOwner) {
      // Same star badge as the members cloud on household details.
      circle = Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            right: -4,
            bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.star, size: 9, color: scheme.onPrimary),
            ),
          ),
        ],
      );
    }

    final chip = Tooltip(message: name, child: circle);
    // Your own chip routes to your profile; a managed member's routes to the
    // You tab so you can act as them. Other real members are display-only.
    if (!isCurrentUser && !isManaged) return chip;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // For a managed member, ask the You tab's "Whose turn?" card to flash
        // so it's obvious where to act as them.
        if (isManaged) {
          ref.read(actAsHighlightProvider.notifier).request();
        }
        context.go(Routes.youTab);
      },
      child: chip,
    );
  }

  /// Stable pastel colour from a seed string - same id → same colour.
  Color _colorFromSeed(String seed) {
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.72).toColor();
  }

  Color _readableOn(Color bg) {
    final hsl = HSLColor.fromColor(bg);
    return hsl.lightness > 0.6 ? Colors.black87 : Colors.white;
  }
}
