import 'avatar.dart';

/// Curated registry of profile avatars. Each entry's [Avatar.id] is what
/// gets stored on `users.avatar`.
///
/// Unlike [PictureRegistry] (households), [lookup] is **nullable** - null
/// means "no selection" and the render layer ([AvatarArtwork]) shows the
/// silhouette fallback. Avoiding a synthetic default keeps the picker
/// honest: a user who hasn't picked is visibly distinct from one who has.
class AvatarRegistry {
  AvatarRegistry._();

  /// Ordered list - picker renders them in this order. More avatars
  /// land as additional PNGs ship into `app/assets/avatars/`; add the
  /// matching entry here.
  static const all = <Avatar>[man1, woman1, girl1, girl2];

  static const man1 = Avatar(id: 'man_1', displayName: 'Man 1');
  static const woman1 = Avatar(id: 'woman_1', displayName: 'Woman 1');
  static const girl1 = Avatar(id: 'girl_1', displayName: 'Girl 1');
  static const girl2 = Avatar(id: 'girl_2', displayName: 'Girl 2');

  /// Look up an avatar by stored id. Returns null for unset, empty, or
  /// unknown values - caller renders the silhouette fallback in that case.
  static Avatar? lookup(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
