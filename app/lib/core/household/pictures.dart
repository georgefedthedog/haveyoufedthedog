import 'picture.dart';

/// Curated registry of household pictures. Each entry's [Picture.id] is
/// what gets stored on `households.picture`.
///
/// Unlike `CharacterRegistry`, [lookup] returns null for unknown / empty
/// ids — the render layer ([PictureArtwork]) decides what "no picture"
/// looks like. That keeps "no selection" a real state rather than a
/// synthetic generic.
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
    paihia,
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

  /// Look up a picture by stored id. Returns null for null, empty, or
  /// unknown values — caller renders the fallback.
  static Picture? lookup(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
