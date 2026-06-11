import 'package:flutter/material.dart';

/// App-wide page background: the theme surface darkened, with the house
/// BL→TR lift (−7% lightness bottom-left rising to −2% top-right).
/// Installed once via [MaterialApp.builder]; scaffolds are transparent so
/// every page sits on this gradient.
class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    // Dark mode stays flat: near-black gradients render as visible
    // banding seams rather than a smooth blend, so the lift is a
    // light-mode-only treat.
    if (theme.brightness == Brightness.dark) {
      return ColoredBox(color: surface, child: child);
    }

    final hsl = HSLColor.fromColor(surface);
    final dark =
        hsl.withLightness((hsl.lightness - 0.07).clamp(0.0, 1.0)).toColor();
    final light =
        hsl.withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0)).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [dark, light],
        ),
      ),
      child: child,
    );
  }
}
