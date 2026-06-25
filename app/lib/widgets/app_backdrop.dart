import 'package:flutter/material.dart';

/// App-wide page background: the theme surface darkened, with the house
/// BL→TR lift (−7% lightness bottom-left rising to +3% top-right), and
/// faint paw prints scattered around the edges (originally the login
/// page's backdrop, promoted to every page).
/// Installed once via [MaterialApp.builder]; scaffolds are transparent so
/// every page sits on this gradient.
class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    final stacked = Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: _PawPrints())),
        child,
      ],
    );

    // Now that this backdrop wraps each routed page (not just the navigator),
    // page transitions fade it. A gradient + overlapping translucent paws
    // can't accept inherited opacity, so Impeller logs a validation break on
    // every transition. Isolating the painted content in a RepaintBoundary
    // makes the fade apply to one flattened layer instead - no validation.
    // Dark mode stays flat: near-black gradients render as visible banding
    // seams rather than a smooth blend, so the lift is a light-mode-only treat.
    if (theme.brightness == Brightness.dark) {
      return RepaintBoundary(child: ColoredBox(color: surface, child: stacked));
    }

    final hsl = HSLColor.fromColor(surface);
    final dark = hsl
        .withLightness((hsl.lightness - 0.07).clamp(0.0, 1.0))
        .toColor();
    final light = hsl
        .withLightness((hsl.lightness + 0.03).clamp(0.0, 1.0))
        .toColor();
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [dark, light],
          ),
        ),
        child: stacked,
      ),
    );
  }
}

/// Faint paw prints scattered around the page edges - pure [Icons.pets]
/// at low opacity, no asset needed.
class _PawPrints extends StatelessWidget {
  const _PawPrints();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.06);
    // (alignment x, alignment y, size, rotation in radians)
    const paws = <(double, double, double, double)>[
      (-0.9, -0.9, 64, -0.4),
      (0.95, -0.55, 44, 0.5),
      (-0.88, -0.15, 38, 0.3),
      (0.9, 0.1, 56, -0.35),
      (-0.92, 0.5, 46, 0.45),
      (0.88, 0.78, 70, -0.2),
      (-0.45, 0.95, 40, 0.25),
    ];
    return Stack(
      children: [
        for (final (x, y, size, angle) in paws)
          Align(
            alignment: Alignment(x, y),
            child: Transform.rotate(
              angle: angle,
              child: Icon(Icons.pets, size: size, color: color),
            ),
          ),
      ],
    );
  }
}
