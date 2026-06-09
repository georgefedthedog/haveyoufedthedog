import 'package:flutter/material.dart';

/// One of the curated household pictures a user can choose for their
/// household. The selected [id] is what we store on `households.picture`.
///
/// Mirror of `Character` (in `core/subjects/character.dart`) but simpler —
/// no expressions, no stage colour. The picture is a single transparent
/// PNG that floats on whatever surface it's drawn over.
///
/// See [PictureRegistry] for the curated set + `lookup` helper.
@immutable
class Picture {
  /// Stable id; what we store on `households.picture`. Don't rename without
  /// a migration story (legacy values fall through to a null lookup).
  final String id;

  /// Human-readable label used in the picker.
  final String displayName;

  const Picture({required this.id, required this.displayName});

  /// Asset path for this picture's PNG.
  String get assetPath => 'assets/households/$id.png';

  /// Material icon used as the fallback whenever the picture is missing
  /// (asset not bundled yet, household has no picture chosen, etc).
  static const IconData fallbackIcon = Icons.home_outlined;
}
