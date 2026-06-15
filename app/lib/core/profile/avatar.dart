import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// One of the curated profile avatars a user can pick for themselves. The
/// selected [id] is what we store on `users.avatar`.
///
/// Bundled avatars ship a single PNG at `assets/avatars/<id>.png`; catalog
/// avatars (served from the `catalog_avatars` PB collection) carry a
/// [remoteImage] download URL instead. Either way, render via
/// [imageProvider] - remote art goes through the shared disk cache so it
/// keeps working offline after the first load.
@immutable
class Avatar {
  /// Stable id; what we store on `users.avatar`. Don't rename without a
  /// migration story (legacy values fall through to null and the widget
  /// renders the silhouette fallback).
  final String id;

  /// Human-readable label used in the picker.
  final String displayName;

  /// Download URL for catalog avatars; null for bundled ones.
  final Uri? remoteImage;

  /// Id of the `catalog_packs` row this avatar belongs to, or null for
  /// bundled art and general-catalog rows (`pack = ''`). Used only to gate
  /// the *picker* to a household's entitled packs - resolution is ungated,
  /// so any chosen avatar renders in any household the user is in.
  final String? packId;

  const Avatar({
    required this.id,
    required this.displayName,
    this.remoteImage,
    this.packId,
  });

  /// Asset path for a bundled avatar's PNG.
  String get assetPath => 'assets/avatars/$id.png';

  /// The avatar art - bundled asset or disk-cached download.
  ImageProvider get imageProvider => remoteImage != null
      ? CachedNetworkImageProvider(remoteImage.toString())
      : AssetImage(assetPath) as ImageProvider;

  /// Material icon used as the fallback whenever the art fails to load
  /// or the user hasn't picked an avatar yet.
  static const IconData fallbackIcon = Icons.person;
}
