import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/household/picture.dart';
import '../home/time_of_day_bucket.dart';

/// Renders a household's chosen [Picture] in the variant matching the
/// current time of day (or [bucketOverride] when supplied - useful for
/// previewing other times).
///
/// When [picture] is null (unset on the household, or unknown id): draws
/// a soft pastel rounded panel with [Picture.fallbackIcon] centred.
class PictureArtwork extends StatelessWidget {
  final Picture? picture;

  /// Forced height. Width follows from `BoxFit.contain` so the aspect
  /// ratio of the underlying PNG is preserved.
  final double? height;

  /// Override the time-of-day bucket used to pick the variant. Handy for
  /// the picker's preview tiles or for screenshot tooling. Defaults to
  /// `bucketFor(DateTime.now())`.
  final TimeOfDayBucket? bucketOverride;

  /// How the PNG fills its box. Defaults to [BoxFit.contain] so the whole
  /// image is visible. Pass [BoxFit.cover] on the home hero to crop the
  /// transparent corners and zoom in to the scene.
  final BoxFit fit;

  const PictureArtwork({
    super.key,
    required this.picture,
    this.height,
    this.bucketOverride,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final p = picture;
    if (p != null) {
      final bucket = bucketOverride ?? bucketFor(DateTime.now());
      return SizedBox(
        height: height,
        child: Image.asset(p.assetPathFor(bucket), fit: fit),
      );
    }

    // Fallback panel - cosy generic house on a cream stage.
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
