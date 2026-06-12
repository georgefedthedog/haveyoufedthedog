import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'character.dart';

/// Renders a character's art at the requested expression.
///
/// When the character declares at least one expression in
/// [Character.available], we draw [Character.imageProviderFor] - a bundled
/// asset or a disk-cached download for catalog characters. If the art is
/// missing or fails to load - or the character has no art at all - we fall
/// back to the character's [Character.fallbackIcon] centred on the
/// coloured stage.
///
/// Remote characters prefetch their other expressions into the disk cache
/// as soon as one renders (same rule as [PictureArtwork]'s time-of-day
/// variants), so a mood flip - idle to sad when a chore goes overdue -
/// never flashes a placeholder.
class CharacterArtwork extends StatelessWidget {
  final Character character;
  final CharacterExpression expression;

  /// Whether the pastel stage colour is drawn behind the artwork. Off for
  /// avatar contexts where the parent already owns the background (the
  /// circular avatar in the character picker, for example).
  final bool stage;

  /// Forced size for the icon glyph; defaults to a sensible value derived
  /// from [LayoutBuilder] constraints. Only used in the fallback path.
  final double? iconSize;

  const CharacterArtwork({
    super.key,
    required this.character,
    this.expression = CharacterExpression.idle,
    this.stage = true,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (character.available.isEmpty) {
      content = _iconFallback();
    } else {
      if (character.remoteExpressions != null) {
        _prefetchOtherExpressions(context);
      }
      content = Image(
        image: character.imageProviderFor(expression),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _iconFallback(),
      );
    }

    if (!stage) return Center(child: content);

    // Gentle diagonal shading - darker toward the bottom-left, lighter
    // toward the top-right - derived from the stage colour so every
    // character gets a matching lift. Same recipe as the subject hero
    // egg and the Friends cards.
    final stageHsl = HSLColor.fromColor(character.stageColor);
    final stageLight = stageHsl
        .withLightness((stageHsl.lightness + 0.05).clamp(0.0, 1.0))
        .toColor();
    final stageDark = stageHsl
        .withLightness((stageHsl.lightness - 0.07).clamp(0.0, 1.0))
        .toColor();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [stageDark, stageLight],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(child: content),
      ),
    );
  }

  /// Warm the disk cache for the expressions we're *not* showing right
  /// now. Errors are swallowed - this is opportunistic; an expression that
  /// fails here just loads on demand later.
  void _prefetchOtherExpressions(BuildContext context) {
    final remote = character.remoteExpressions;
    if (remote == null) return;
    final showing = remote[character.resolve(expression)];
    for (final url in remote.values) {
      if (url == showing) continue;
      precacheImage(
        CachedNetworkImageProvider(url.toString()),
        context,
        onError: (_, _) {},
      );
    }
  }

  Widget _iconFallback() {
    final color = _iconColorOn(character.stageColor);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            iconSize ??
            (constraints.biggest.shortestSide.isFinite
                ? constraints.biggest.shortestSide * 0.55
                : 48.0);
        return Icon(character.fallbackIcon, size: size, color: color);
      },
    );
  }

  // Stage colours are pastel - use a darker ink so the icon reads.
  Color _iconColorOn(Color stage) {
    // Mix the stage colour toward black: rough heuristic that picks a
    // legible foreground without needing per-character configuration.
    final hsl = HSLColor.fromColor(stage);
    return hsl.withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0)).toColor();
  }
}
