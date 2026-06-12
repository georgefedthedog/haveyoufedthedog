import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/household/household_members_controller.dart';
import '../../core/profile/avatars.dart';
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

class _Avatar extends StatelessWidget {
  /// User's chosen avatar id, or null if they haven't picked one yet.
  /// When non-null we render the matching [AvatarArtwork]; when null we
  /// fall back to the seeded-initial circle so households mid-rollout
  /// still have something personal instead of identical silhouettes.
  final String? avatarId;
  final String initial;
  final String seed;
  final String name;
  final bool isOwner;

  const _Avatar({
    required this.avatarId,
    required this.initial,
    required this.seed,
    required this.name,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = AvatarRegistry.lookup(avatarId);

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

    return Tooltip(message: name, child: circle);
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
