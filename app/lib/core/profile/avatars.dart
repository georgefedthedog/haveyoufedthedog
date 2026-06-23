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
  static const all = <Avatar>[
    man1,
    man2,
    woman1,
    woman2,
    girl1,
    girl2,
    boy1,
    boy2,
  ];

  static const man1 = Avatar(id: 'man_1', displayName: 'Man 1', sortOrder: 1000);
  static const man2 = Avatar(id: 'man_2', displayName: 'Man 2', sortOrder: 1010);
  static const woman1 = Avatar(id: 'woman_1', displayName: 'Woman 1', sortOrder: 1020);
  static const woman2 = Avatar(id: 'woman_2', displayName: 'Woman 2', sortOrder: 1030);
  static const girl1 = Avatar(id: 'girl_1', displayName: 'Girl 1', sortOrder: 1040);
  static const girl2 = Avatar(id: 'girl_2', displayName: 'Girl 2', sortOrder: 1050);
  static const boy1 = Avatar(id: 'boy_1', displayName: 'Boy 1', sortOrder: 1060);
  static const boy2 = Avatar(id: 'boy_2', displayName: 'Boy 2', sortOrder: 1070);

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
