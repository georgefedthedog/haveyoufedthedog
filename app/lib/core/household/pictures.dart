import 'picture.dart';

/// Curated registry of household pictures. Each entry's [Picture.id] is
/// what gets stored on `households.picture`.
///
/// [lookup] always returns a non-null [Picture]: it falls back to
/// [defaultPicture] for null, empty, or unknown ids. That way every
/// household renders a real house rather than the generic placeholder.
class PictureRegistry {
  PictureRegistry._();

  /// Ordered list — picker renders them in this order.
  static const all = <Picture>[
    paihia,
    terrace,
  ];

  static const paihia = Picture(id: 'paihia', displayName: 'Paihia House');
  static const terrace = Picture(id: 'terrace', displayName: 'Terrace');

  /// Shown for households that haven't picked a picture yet (or whose
  /// stored id no longer matches a registry entry).
  static const defaultPicture = paihia;

  /// Look up a picture by stored id. Falls back to [defaultPicture] for
  /// null, empty, or unknown values.
  static Picture lookup(String? id) {
    if (id == null || id.isEmpty) return defaultPicture;
    for (final p in all) {
      if (p.id == id) return p;
    }
    return defaultPicture;
  }
}
