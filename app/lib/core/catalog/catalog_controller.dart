import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../features/home/time_of_day_bucket.dart';
import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import '../household/picture.dart';
import '../household/pictures.dart';
import '../profile/avatar.dart';
import '../profile/avatars.dart';
import '../storage/shared_preferences_provider.dart';
import '../subjects/character.dart';
import '../subjects/characters.dart';
import 'catalog.dart';

part 'catalog_controller.g.dart';

/// Fetches the enabled rows of the three `catalog_*` collections once per
/// session (rebuilds on auth change). **Fail-soft by design:** when the
/// fetch fails - offline, old server without the collections - it falls
/// back to the last successful fetch, persisted as a JSON snapshot in
/// SharedPreferences. Image bytes live in the cached_network_image disk
/// cache, so together the two caches make remote art fully offline-capable
/// after it's been seen once. Only a fresh install that has never reached
/// the server (or a snapshot that fails to parse) degrades to
/// [RemoteCatalog.empty] / bundled-only.
@Riverpod(keepAlive: true)
Future<RemoteCatalog> remoteCatalog(Ref ref) async {
  final pbFuture = ref.watch(pocketbaseClientProvider.future);
  // Identity-scoped watch - see HouseholdsController for why not `.future`.
  final userIdFuture = ref.watch(
    authControllerProvider.selectAsync((a) => a.userId),
  );
  final prefsFuture = ref.watch(sharedPreferencesProvider.future);

  final pb = await pbFuture;
  final userId = await userIdFuture;
  final prefs = await prefsFuture;

  if (userId == null) return RemoteCatalog.empty;

  try {
    final results = await Future.wait([
      _rows(pb, 'catalog_avatars'),
      _rows(pb, 'catalog_pictures'),
      _rows(pb, 'catalog_characters'),
    ]);
    await _saveSnapshot(prefs, results);
    return RemoteCatalog(
      avatars: [for (final r in results[0]) ?_avatarFrom(pb, r)],
      pictures: [for (final r in results[1]) ?_pictureFrom(pb, r)],
      characters: [for (final r in results[2]) ?_characterFrom(pb, r)],
    );
  } catch (e) {
    debugPrint('Remote catalog unavailable, trying last snapshot: $e');
    return _loadSnapshot(prefs, pb) ?? RemoteCatalog.empty;
  }
}

const _kSnapshotKey = 'catalog_snapshot_v1';

/// Persist the raw PB records of a successful fetch. Stored as records
/// (not mapped models) so [_loadSnapshot] reuses the exact same mapping
/// code path - URLs, colour parsing, expression sets - as a live fetch.
Future<void> _saveSnapshot(
  SharedPreferences prefs,
  List<List<RecordModel>> results,
) async {
  try {
    await prefs.setString(
      _kSnapshotKey,
      jsonEncode({
        'avatars': [for (final r in results[0]) r.toJson()],
        'pictures': [for (final r in results[1]) r.toJson()],
        'characters': [for (final r in results[2]) r.toJson()],
      }),
    );
  } catch (e) {
    // A failed save just means a stale (or no) snapshot next time the
    // device is offline - never worth failing the live fetch over.
    debugPrint('Catalog snapshot save failed: $e');
  }
}

RemoteCatalog? _loadSnapshot(SharedPreferences prefs, PocketBase pb) {
  final raw = prefs.getString(_kSnapshotKey);
  if (raw == null) return null;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    List<RecordModel> records(String key) => [
      for (final j in map[key] as List? ?? const [])
        RecordModel.fromJson((j as Map).cast<String, dynamic>()),
    ];
    return RemoteCatalog(
      avatars: [for (final r in records('avatars')) ?_avatarFrom(pb, r)],
      pictures: [for (final r in records('pictures')) ?_pictureFrom(pb, r)],
      characters: [
        for (final r in records('characters')) ?_characterFrom(pb, r),
      ],
    );
  } catch (e) {
    debugPrint('Catalog snapshot unreadable, using bundled art only: $e');
    return null;
  }
}

/// Merged bundled + remote catalog. Synchronous and always usable: starts
/// as bundled-only, re-emits once (if) the remote fetch lands.
@Riverpod(keepAlive: true)
Catalog catalog(Ref ref) {
  final remote =
      ref.watch(remoteCatalogProvider).valueOrNull ?? RemoteCatalog.empty;
  return Catalog(
    avatars: _merge(AvatarRegistry.all, remote.avatars, (a) => a.id),
    pictures: _merge(PictureRegistry.all, remote.pictures, (p) => p.id),
    characters: _merge(CharacterRegistry.all, remote.characters, (c) => c.id),
  );
}

Future<List<RecordModel>> _rows(PocketBase pb, String collection) =>
    pb.collection(collection).getFullList(
      filter: 'enabled = true',
      sort: 'sort_order,created',
    );

List<T> _merge<T>(List<T> bundled, List<T> remote, String Function(T) idOf) {
  final seen = bundled.map(idOf).toSet();
  return [
    ...bundled,
    for (final r in remote)
      if (seen.add(idOf(r))) r,
  ];
}

Avatar? _avatarFrom(PocketBase pb, RecordModel r) {
  final slug = r.getStringValue('slug');
  final image = r.getStringValue('image');
  if (slug.isEmpty || image.isEmpty) return null;
  return Avatar(
    id: slug,
    displayName: r.getStringValue('display_name'),
    remoteImage: pb.files.getUrl(r, image),
  );
}

Picture? _pictureFrom(PocketBase pb, RecordModel r) {
  final slug = r.getStringValue('slug');
  if (slug.isEmpty) return null;
  final variants = <TimeOfDayBucket, Uri>{};
  for (final bucket in TimeOfDayBucket.values) {
    final file = r.getStringValue(bucket.fileName);
    if (file.isEmpty) return null; // All five are required; skip bad rows.
    variants[bucket] = pb.files.getUrl(r, file);
  }
  return Picture(
    id: slug,
    displayName: r.getStringValue('display_name'),
    remoteVariants: variants,
  );
}

Character? _characterFrom(PocketBase pb, RecordModel r) {
  final slug = r.getStringValue('slug');
  if (slug.isEmpty) return null;
  final expressions = <CharacterExpression, Uri>{};
  for (final e in CharacterExpression.values) {
    final file = r.getStringValue(e.name);
    if (file.isNotEmpty) expressions[e] = pb.files.getUrl(r, file);
  }
  if (!expressions.containsKey(CharacterExpression.idle)) return null;
  final award = r.getStringValue('award');
  return Character(
    id: slug,
    displayName: r.getStringValue('display_name'),
    stageColor: _stageColor(r.getStringValue('base_color')),
    fallbackIcon: Icons.task_alt,
    available: expressions.keys.toSet(),
    remoteExpressions: expressions,
    remoteAward: award.isEmpty ? null : pb.files.getUrl(r, award),
  );
}

Color _stageColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null || cleaned.length != 6) return AppColors.stageCream;
  return Color(0xFF000000 | value);
}
