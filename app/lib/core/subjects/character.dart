import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'character_messages.dart';

/// Expressions a character can be drawn in. Not every character has every
/// expression - see [Character.imageProviderFor] for the fallback chain.
///
/// Enum value names match the on-disk file names
/// (`assets/subjects/<id>/<name>.png`) and the file fields on the
/// `catalog_characters` PB collection, so there's a single vocabulary
/// across art, server and code.
enum CharacterExpression {
  /// Default; on home cards, subject hero, picker thumbnails.
  idle,

  /// "All happy and fed" - subject detail when everything for today is done.
  happy,

  /// "Hey, the bowl's empty" - pending / overdue.
  sad,

  /// Mid-confetti, arms up. Completion celebration screen.
  celebrate,

  /// Peacefully snoozing - home's "nothing due today" state.
  sleeping,
}

/// One of the curated character templates a subject can be drawn as.
///
/// Characters live in [CharacterRegistry] (bundled) and the
/// `catalog_characters` PB collection (remote), merged by the catalog
/// provider. The stored value on `subjects.icon` is the [id] string - see
/// [CharacterRegistry.lookup] for the fallback chain. Bundled characters
/// resolve art from `assets/subjects/<id>/`; remote ones carry
/// [remoteExpressions] download URLs and go through the shared disk cache.
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

  /// Download URLs per expression for remote characters; null for bundled
  /// ones. When set, [available] mirrors its keys.
  final Map<CharacterExpression, Uri>? remoteExpressions;

  /// Download URL for the remote trophy pose; null for bundled characters
  /// (which resolve `assets/subjects/<id>/award.png`) and for remote ones
  /// that haven't shipped it.
  final Uri? remoteAward;

  /// Ids of the `catalog_packs` rows this character belongs to; empty for
  /// bundled art and general-catalog rows (no pack). A character can be in
  /// several packs (e.g. its group + an "everything" pack). Used only to gate
  /// the *picker* to a household's entitled packs - resolution is ungated.
  final List<String> packIds;

  /// Picker sort position. Remote characters take it from the catalog row's
  /// `sort_order`; bundled ones are assigned in [CharacterRegistry] so they
  /// interleave into the right group. The merged picker list is sorted by this.
  final int sortOrder;

  /// Author-supplied copy overrides (mood lines, award title/thanks) for
  /// remote characters; null for bundled ones, which keep their hardcoded
  /// copy in `character_message.dart` / `awards_controller.dart`.
  final CharacterMessages? messages;

  /// When true, this character is reserved (e.g. a private/personal pack) and
  /// is excluded from the free streak rewards. Defaults false (claimable).
  /// Doesn't affect resolution or the pickers - only the rewards page.
  final bool rewardExcluded;

  /// `{lang: name}` translations of [displayName] from the catalog row's
  /// `display_name_i18n` column; empty for bundled characters (theirs are
  /// ARB keys - see `localizedCharacterName`).
  final Map<String, String> nameI18n;

  const Character({
    required this.id,
    required this.displayName,
    required this.stageColor,
    required this.fallbackIcon,
    this.available = const {CharacterExpression.idle},
    this.remoteExpressions,
    this.remoteAward,
    this.packIds = const [],
    this.sortOrder = 0,
    this.messages,
    this.rewardExcluded = false,
    this.nameI18n = const {},
  });

  /// The closest available expression - defaults via
  /// `celebrating → happy → idle`.
  CharacterExpression resolve(CharacterExpression expression) {
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
    return ordered.firstWhere(
      available.contains,
      orElse: () => CharacterExpression.idle,
    );
  }

  /// Asset path for the closest expression a bundled character ships.
  String assetFor(CharacterExpression expression) =>
      'assets/subjects/$id/${resolve(expression).name}.png';

  /// Art for the closest available expression - bundled asset or
  /// disk-cached download.
  ImageProvider imageProviderFor(CharacterExpression expression) {
    final remote = remoteExpressions;
    if (remote == null) return AssetImage(assetFor(expression));
    final url = remote[resolve(expression)] ?? remote[CharacterExpression.idle];
    if (url == null) return AssetImage(assetFor(expression));
    return CachedNetworkImageProvider(url.toString());
  }

  /// The character holding its weekly trophy - used on the featured
  /// award cards. Not an expression: it's a one-off celebratory pose.
  /// Remote characters without one fall back to the celebrate chain.
  ImageProvider get awardImageProvider {
    if (remoteExpressions == null) {
      return AssetImage('assets/subjects/$id/award.png');
    }
    final award = remoteAward;
    if (award != null) return CachedNetworkImageProvider(award.toString());
    return imageProviderFor(CharacterExpression.celebrate);
  }
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
