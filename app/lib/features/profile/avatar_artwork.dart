import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/profile/avatar.dart';

/// Renders a user's chosen [Avatar] as a circular badge.
///
/// When [avatar] is null (user hasn't picked yet, or unknown id): draws a
/// silhouette ([Avatar.fallbackIcon]) on the same cream circle, so the
/// shape and footprint stay identical to a picked avatar - swapping one
/// for the other in member rows doesn't cause reflow.
class AvatarArtwork extends StatelessWidget {
  final Avatar? avatar;

  /// Diameter of the circle in logical pixels. Default sized for the
  /// You-tab hero; pass smaller (e.g. 44) for member rows or the
  /// "completed by" line in the celebration overlay.
  final double size;

  const AvatarArtwork({super.key, required this.avatar, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = avatar;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.stageCream,
      foregroundColor: theme.colorScheme.onSurfaceVariant,
      child: a == null
          ? Icon(Avatar.fallbackIcon, size: size * 0.55)
          : ClipOval(
              child: Image(
                image: a.imageProvider,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Avatar.fallbackIcon, size: size * 0.55),
              ),
            ),
    );
  }
}
