import '../household/picture.dart';
import '../household/pictures.dart';
import '../profile/avatar.dart';
import '../subjects/character.dart';
import '../subjects/characters.dart';

/// The remote half of the content catalog - enabled rows from the three
/// `catalog_*` PB collections, mapped to the same model types as the
/// bundled registries. Empty when signed out, offline, or the server
/// doesn't have the collections yet.
class RemoteCatalog {
  final List<Avatar> avatars;
  final List<Picture> pictures;
  final List<Character> characters;

  /// Display names of enabled `catalog_packs` rows, keyed by pack id.
  /// Used to label the household's applied packs - pack *codes* never
  /// reach the client (hidden field).
  final Map<String, String> packNames;

  const RemoteCatalog({
    required this.avatars,
    required this.pictures,
    required this.characters,
    this.packNames = const {},
  });

  static const empty = RemoteCatalog(
    avatars: [],
    pictures: [],
    characters: [],
  );
}

/// Merged view over bundled + remote art - what every picker and lookup
/// call site reads (via `catalogProvider`). Bundled entries always come
/// first and win slug collisions, so remote rows can never shadow art
/// that ships in the binary.
///
/// Lookup semantics match the old static registries exactly:
/// - [lookupAvatar] is nullable - null means "render the silhouette".
/// - [lookupPicture] falls back to [PictureRegistry.defaultPicture].
/// - [lookupCharacter] falls back through [CharacterRegistry.lookup]'s
///   legacy-token mapping, ending at the generic character.
class Catalog {
  final List<Avatar> avatars;
  final List<Picture> pictures;
  final List<Character> characters;

  /// Pack id → display name for enabled packs (see [RemoteCatalog.packNames]).
  final Map<String, String> packNames;

  const Catalog({
    required this.avatars,
    required this.pictures,
    required this.characters,
    this.packNames = const {},
  });

  /// Display name for an applied pack id; null when the pack is unknown
  /// (disabled, deleted, or the catalog hasn't loaded) - callers skip it.
  String? packName(String id) => packNames[id];

  Avatar? lookupAvatar(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final a in avatars) {
      if (a.id == id) return a;
    }
    return null;
  }

  Picture lookupPicture(String? id) {
    if (id == null || id.isEmpty) return PictureRegistry.defaultPicture;
    for (final p in pictures) {
      if (p.id == id) return p;
    }
    return PictureRegistry.defaultPicture;
  }

  Character lookupCharacter(String? id) {
    if (id == null || id.isEmpty) return CharacterRegistry.generic;
    for (final c in characters) {
      if (c.id == id) return c;
    }
    return CharacterRegistry.lookup(id);
  }
}
