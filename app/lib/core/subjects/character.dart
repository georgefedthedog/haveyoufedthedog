import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Expressions a character can be drawn in. Not every character has every
/// expression — see [Character.assetFor] for the fallback chain.
///
/// Enum value names match the on-disk file names
/// (`assets/subjects/<id>/<name>.png`) so there's a single vocabulary
/// across art and code.
enum CharacterExpression {
  /// Default; on home cards, subject hero, picker thumbnails.
  idle,

  /// "All happy and fed" — subject detail when everything for today is done.
  happy,

  /// "Hey, the bowl's empty" — pending / overdue.
  sad,

  /// Mid-confetti, arms up. Completion celebration screen.
  celebrate,

  /// Peacefully snoozing — home's "nothing due today" state.
  sleeping,
}

/// One of the curated character templates a subject can be drawn as.
///
/// Characters live in [CharacterRegistry] (lower-level lookup) and are
/// picked via the [CharacterPicker] widget. The stored value on
/// `subjects.icon` is the [id] string — see [CharacterRegistry.lookup]
/// for the fallback chain.
@immutable
class Character {
  /// Stable id; what we store on `subjects.icon`. Don't rename without a
  /// migration story (legacy values fall through to [Characters.generic]).
  final String id;

  /// Human-readable label used in the picker.
  final String displayName;

  /// Pastel background colour for the hero stage on home / subject detail.
  final Color stageColor;

  /// Foreground icon used wherever real character art hasn't been
  /// shipped yet. Phase A renders this; Phase B+ swaps in PNGs while
  /// keeping the same call sites.
  final IconData fallbackIcon;

  /// Which expressions ship with this character. The picker uses [idle];
  /// the celebration overlay tries [celebrating] then falls back to
  /// [happy] then [idle].
  final Set<CharacterExpression> available;

  const Character({
    required this.id,
    required this.displayName,
    required this.stageColor,
    required this.fallbackIcon,
    this.available = const {CharacterExpression.idle},
  });

  /// Asset path for the closest expression we ship — defaults via
  /// `celebrating → happy → idle`.
  String assetFor(CharacterExpression expression) {
    final ordered = switch (expression) {
      CharacterExpression.celebrate => const [
          CharacterExpression.celebrate,
          CharacterExpression.happy,
          CharacterExpression.idle,
        ],
      CharacterExpression.happy => const [
          CharacterExpression.happy,
          CharacterExpression.celebrate,
          CharacterExpression.idle,
        ],
      CharacterExpression.sad => const [
          CharacterExpression.sad,
          CharacterExpression.idle,
        ],
      CharacterExpression.sleeping => const [
          CharacterExpression.sleeping,
          CharacterExpression.idle,
        ],
      CharacterExpression.idle => const [CharacterExpression.idle],
    };
    final pick = ordered.firstWhere(
      available.contains,
      orElse: () => CharacterExpression.idle,
    );
    return 'assets/subjects/$id/${pick.name}.png';
  }

  /// Asset path for the idle expression — most-used shortcut.
  String get idleAsset => assetFor(CharacterExpression.idle);
}

/// Stage colours grouped here so the registry stays tidy.
class CharacterStage {
  CharacterStage._();
  static const dog = AppColors.stagePeach;
  static const cat = AppColors.stageLavender;
  static const plant = AppColors.stageMint;
  static const bin = AppColors.stageMint;
  static const fish = AppColors.stageSky;
  static const generic = AppColors.stageCream;
}
