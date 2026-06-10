import 'package:flutter/material.dart';

/// One of the curated profile avatars a user can pick for themselves. The
/// selected [id] is what we store on `users.avatar`.
///
/// Each avatar ships a single PNG at `assets/avatars/<id>.png`. Resolve it
/// with [assetPath].
@immutable
class Avatar {
  /// Stable id; what we store on `users.avatar`. Don't rename without a
  /// migration story (legacy values fall through to null and the widget
  /// renders the silhouette fallback).
  final String id;

  /// Human-readable label used in the picker.
  final String displayName;

  const Avatar({required this.id, required this.displayName});

  /// Asset path for this avatar's PNG.
  String get assetPath => 'assets/avatars/$id.png';

  /// Material icon used as the fallback whenever the asset fails to load
  /// or the user hasn't picked an avatar yet.
  static const IconData fallbackIcon = Icons.person_outline;
}
