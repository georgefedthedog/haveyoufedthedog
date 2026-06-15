import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/home/time_of_day_bucket.dart';

/// One of the curated household pictures a user can choose for their
/// household. The selected [id] is what we store on `households.picture`.
///
/// Each picture has five variants - one per [TimeOfDayBucket]. Bundled
/// pictures ship them as PNGs at `assets/households/<id>/<bucket>.png`;
/// catalog pictures (served from the `catalog_pictures` PB collection)
/// carry [remoteVariants] download URLs instead. Either way, render via
/// [imageProviderFor] - remote art goes through the shared disk cache so
/// it keeps working offline after the first load.
@immutable
class Picture {
  /// Stable id; what we store on `households.picture`. Don't rename without
  /// a migration story (legacy values fall through to the default picture).
  final String id;

  /// Human-readable label used in the picker.
  final String displayName;

  /// Download URLs per bucket for catalog pictures; null for bundled ones.
  final Map<TimeOfDayBucket, Uri>? remoteVariants;

  /// Id of the `catalog_packs` row this picture belongs to, or null for
  /// bundled art and general-catalog rows (`pack = ''`). Used only to gate
  /// the *picker* to a household's entitled packs - resolution is ungated,
  /// so a household's chosen picture renders in the switcher even from
  /// another household that lacks the pack.
  final String? packId;

  const Picture({
    required this.id,
    required this.displayName,
    this.remoteVariants,
    this.packId,
  });

  /// Asset path for a bundled picture's variant matching [bucket].
  String assetPathFor(TimeOfDayBucket bucket) =>
      'assets/households/$id/${bucket.fileName}.png';

  /// The variant matching [bucket] - bundled asset or disk-cached download.
  ImageProvider imageProviderFor(TimeOfDayBucket bucket) {
    final remote = remoteVariants?[bucket];
    return remote != null
        ? CachedNetworkImageProvider(remote.toString())
        : AssetImage(assetPathFor(bucket)) as ImageProvider;
  }

  /// Material icon used as the fallback whenever a variant fails to load.
  static const IconData fallbackIcon = Icons.home;
}
