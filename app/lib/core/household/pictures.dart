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
    cottage,
    terrace,
    semi,
    detached,
    paihia,
    barn,
    farm,
    beach,
    flat,
  ];

  static const cottage = Picture(id: 'cottage', displayName: 'Cottage');
  static const terrace = Picture(id: 'terrace', displayName: 'Terrace');
  static const semi = Picture(id: 'semi', displayName: 'Semi-detached');
  static const detached = Picture(id: 'detached', displayName: 'Detached');
  static const paihia = Picture(id: 'paihia', displayName: 'Paihia House');
  static const barn = Picture(id: 'barn', displayName: 'Barn');
  static const farm = Picture(id: 'farm', displayName: 'Farmhouse');
  static const beach = Picture(id: 'beach', displayName: 'Beach house');
  static const flat = Picture(id: 'flat', displayName: 'Flat');

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
