import 'package:flutter/material.dart';

import 'character.dart';

/// Renders a character's art at the requested expression.
///
/// **Phase A:** ships placeholder art — a coloured stage with the
/// character's [Character.fallbackIcon] centred on it. As real PNG art is
/// dropped into `assets/characters/<id>/<expression>.png` in later
/// phases, swap to `Image.asset(...)` here in one place and every call
/// site picks it up.
class CharacterArtwork extends StatelessWidget {
  final Character character;
  final CharacterExpression expression;

  /// Whether the pastel stage colour is drawn behind the artwork. Off for
  /// avatar contexts where the parent already owns the background (the
  /// circular avatar in the character picker, for example).
  final bool stage;

  /// Forced size for the icon glyph; defaults to a sensible value derived
  /// from [LayoutBuilder] constraints.
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
    final color = _iconColorOn(character.stageColor);

    final Widget glyph = LayoutBuilder(
      builder: (context, constraints) {
        final size = iconSize ??
            (constraints.biggest.shortestSide.isFinite
                ? constraints.biggest.shortestSide * 0.55
                : 48.0);
        return Icon(character.fallbackIcon, size: size, color: color);
      },
    );

    if (!stage) return Center(child: glyph);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: character.stageColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(child: glyph),
      ),
    );
  }

  // Stage colours are pastel — use a darker ink so the icon reads.
  Color _iconColorOn(Color stage) {
    // Mix the stage colour toward black: rough heuristic that picks a
    // legible foreground without needing per-character configuration.
    final hsl = HSLColor.fromColor(stage);
    return hsl.withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0)).toColor();
  }
}
