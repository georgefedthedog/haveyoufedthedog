import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/household/picture.dart';
import '../home/time_of_day_bucket.dart';

/// Renders a household's chosen [Picture] in the variant matching the
/// current time of day (or [bucketOverride] when supplied - useful for
/// previewing other times).
///
/// When [picture] is null (unset on the household, or unknown id) - or a
/// variant fails to load before it's ever been cached - draws a soft
/// pastel rounded panel with [Picture.fallbackIcon] centred.
///
/// Remote pictures prefetch their other four time-of-day variants into
/// the disk cache as soon as one renders, so the scene never flips to a
/// placeholder when the bucket rolls over (e.g. evening at 5pm).
class PictureArtwork extends StatelessWidget {
  /// The standard aspect ratio (width / height) for showing a house picture as
  /// a card - the home hero, the rewards tiles, the featured reward card. A
  /// 7:5 photo-print framing; the art is cover-cropped to fit. One constant so
  /// every house surface stays in step.
  static const double houseAspectRatio = 7 / 5;

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
      if (p.remoteVariants != null) _prefetchOtherVariants(context, p, bucket);
      return SizedBox(
        height: height,
        child: Image(
          image: p.imageProviderFor(bucket),
          fit: fit,
          errorBuilder: (context, _, _) => _fallbackPanel(context),
        ),
      );
    }

    return SizedBox(height: height, child: _fallbackPanel(context));
  }

  /// Warm the disk cache for the variants we're *not* showing right now.
  /// Errors are swallowed - this is opportunistic; the bucket that fails
  /// here just loads on demand later.
  void _prefetchOtherVariants(
    BuildContext context,
    Picture p,
    TimeOfDayBucket current,
  ) {
    for (final bucket in TimeOfDayBucket.values) {
      if (bucket == current) continue;
      precacheImage(p.imageProviderFor(bucket), context, onError: (_, _) {});
    }
  }

  // Fallback panel - cosy generic house on a cream stage.
  Widget _fallbackPanel(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
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
    );
  }
}
