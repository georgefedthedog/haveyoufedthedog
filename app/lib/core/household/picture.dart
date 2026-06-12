import 'package:flutter/material.dart';

import '../../features/home/time_of_day_bucket.dart';

/// One of the curated household pictures a user can choose for their
/// household. The selected [id] is what we store on `households.picture`.
///
/// Each picture ships five PNG variants - one per [TimeOfDayBucket] -
/// living at `assets/households/<id>/<bucket>.png`. Resolve a path with
/// [assetPathFor].
@immutable
class Picture {
  /// Stable id; what we store on `households.picture`. Don't rename without
  /// a migration story (legacy values fall through to the default picture).
  final String id;

  /// Human-readable label used in the picker.
  final String displayName;

  const Picture({required this.id, required this.displayName});

  /// Asset path for the variant matching [bucket].
  String assetPathFor(TimeOfDayBucket bucket) =>
      'assets/households/$id/${bucket.fileName}.png';

  /// Material icon used as the fallback whenever a variant fails to load.
  static const IconData fallbackIcon = Icons.home_outlined;
}
