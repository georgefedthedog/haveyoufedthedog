import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/household/picture.dart';

/// Renders a household's chosen [Picture].
///
/// When [picture] is non-null: draws the PNG via [Image.asset], scaled to
/// fit the box.
///
/// When [picture] is null (unset on the household, or unknown id): draws
/// a soft pastel rounded panel with [Picture.fallbackIcon] centred —
/// keeping the surface inviting rather than blank.
class PictureArtwork extends StatelessWidget {
  final Picture? picture;

  /// Forced height. Width follows from `BoxFit.contain` so the aspect
  /// ratio of the underlying PNG is preserved.
  final double? height;

  const PictureArtwork({super.key, required this.picture, this.height});

  @override
  Widget build(BuildContext context) {
    final p = picture;
    if (p != null) {
      return SizedBox(
        height: height,
        child: Image.asset(p.assetPath, fit: BoxFit.contain),
      );
    }

    // Fallback panel — cosy generic house on a cream stage.
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.stageCream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Icon(
              Picture.fallbackIcon,
              size: (height ?? 120) * 0.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
