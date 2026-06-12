import 'package:flutter/material.dart';

/// A soft sky gradient that backs the household picture on the home page.
///
/// The gradient swings through five buckets across the day:
/// - **pre-dawn** (04–06): indigo → soft peach
/// - **morning** (06–11): warm peach → cream
/// - **midday** (11–16): soft sky blue → cream
/// - **evening** (16–19): apricot → lavender
/// - **night** (19–04): deep indigo → muted slate
///
/// Pure Flutter primitives - no images, no extra assets. Wrap the
/// `PictureArtwork` (and its badge) in `HouseStage(child: …)` and the
/// backdrop appears behind it.
class HouseStage extends StatelessWidget {
  final Widget child;

  /// Override for testing / showcase. Defaults to `DateTime.now()`.
  final DateTime? now;

  /// Padding applied around the child so the picture floats slightly
  /// inside the stage rather than touching its edges.
  final EdgeInsets padding;

  /// Corner radius for the stage. Matches the cosy card feel elsewhere.
  final double borderRadius;

  const HouseStage({
    super.key,
    required this.child,
    this.now,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final t = now ?? DateTime.now();
    final skyColors = _gradientFor(t);
    final grass = _grassFor(t);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skyColors,
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Grass band at the bottom - short fade from transparent at the
          // horizon, then solid grass for most of the band so it reads as
          // ground, not a hairline. Drawn first so the house's built-in
          // lawn overlays on top, hiding any colour mismatch.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [grass.withValues(alpha: 0), grass, grass],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Non-positioned, full-width child - sizes the Stack vertically
          // and is drawn on top of the grass.
          SizedBox(
            width: double.infinity,
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

/// Picks (top, bottom) sky colours for the current hour. Hard buckets for
/// phase 1 - easy to read, easy to tweak; we can interpolate at hour
/// boundaries later if the jump feels abrupt.
List<Color> _gradientFor(DateTime t) {
  final h = t.hour;
  if (h < 4 || h >= 19) {
    // Night
    return const [Color(0xFF3A4170), Color(0xFF7F6FAF)];
  }
  if (h < 6) {
    // Pre-dawn
    return const [Color(0xFF4D5380), Color(0xFFFFD0B0)];
  }
  if (h < 11) {
    // Morning
    return const [Color(0xFFFFD9B5), Color(0xFFFAF3E8)];
  }
  if (h < 16) {
    // Midday
    return const [Color(0xFFB8DAEC), Color(0xFFFAF3E8)];
  }
  // Evening (16–19)
  return const [Color(0xFFFFA987), Color(0xFFD4C0E8)];
}

/// Grass colour for the foreground strip - same bucket scheme as the sky.
Color _grassFor(DateTime t) {
  final h = t.hour;
  if (h < 4 || h >= 19) return const Color(0xFF4A6B4F); // night
  if (h < 6) return const Color(0xFF6B8870); // pre-dawn
  if (h < 11) return const Color(0xFF9CC183); // morning
  if (h < 16) return const Color(0xFFA3CB87); // midday
  return const Color(0xFF8AAE73); // evening
}
