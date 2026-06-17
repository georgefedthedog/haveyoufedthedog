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
import '../household/current_household_controller.dart';
import '../household/households_controller.dart';
import '../household/picture.dart';
import '../household/pictures.dart';
import '../profile/avatar.dart';
import '../profile/avatars.dart';
import '../storage/shared_preferences_provider.dart';
import '../subjects/character.dart';
import '../subjects/character_messages.dart';
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
      pb.collection('catalog_packs').getFullList(filter: 'enabled = true'),
    ]);
    await _saveSnapshot(prefs, results);
    return _catalogFrom(pb, results);
  } catch (e) {
    debugPrint('Remote catalog unavailable, trying last snapshot: $e');
    return _loadSnapshot(prefs, pb) ?? RemoteCatalog.empty;
  }
}

RemoteCatalog _catalogFrom(PocketBase pb, List<List<RecordModel>> results) {
  return RemoteCatalog(
    avatars: [for (final r in results[0]) ?_avatarFrom(pb, r)],
    pictures: [for (final r in results[1]) ?_pictureFrom(pb, r)],
    characters: [for (final r in results[2]) ?_characterFrom(pb, r)],
    packNames: {
      for (final r in results[3])
        if (r.getStringValue('name').isNotEmpty) r.id: r.getStringValue('name'),
    },
  );
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
        'packs': [for (final r in results[3]) r.toJson()],
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
    return _catalogFrom(pb, [
      records('avatars'),
      records('pictures'),
      records('characters'),
      records('packs'),
    ]);
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
    packNames: remote.packNames,
  );
}

/// The art a user may select in the pickers - bundled and general-catalog
/// art (always), plus packed art they're entitled to. Entitlement differs
/// by art *kind*, matching what each thing belongs to:
///
/// - **Avatars** are personal, so they're gated by the *union* of packs
///   across all the user's households - a packed avatar can be chosen from
///   any household once any of the user's households has the pack.
/// - **Pictures** and **characters** belong to a household, so they're gated
///   by the *current* household's packs only.
///
/// This is the entitlement gate that used to live in the catalog fetch
/// itself. Rendering (resolving any chosen id) goes through [catalogProvider]
/// instead, which is deliberately ungated so chosen art travels across the
/// user's households. Disabled-pack art is already absent from [catalog]
/// (the fetch drops it), so it can't leak into the picker here either.
@Riverpod(keepAlive: true)
SelectableCatalog selectableCatalog(Ref ref) {
  final catalog = ref.watch(catalogProvider);
  // Current household's packs gate pictures + characters. Selected as a
  // stable joined string so unrelated household churn (renames, refetches)
  // doesn't rebuild the picker - only an actual pack change does.
  final householdPacksKey = ref.watch(
    currentHouseholdControllerProvider.select(
      (h) => (h.valueOrNull?.packIds ?? const <String>[]).join(','),
    ),
  );
  // Union of packs across all the user's households gates avatars. Sorted
  // before joining so the key is order-independent (same stability goal).
  final avatarPacksKey = ref.watch(
    householdsControllerProvider.select((async) {
      final union = <String>{};
      for (final h in async.valueOrNull ?? const []) {
        union.addAll(h.packIds);
      }
      final sorted = union.toList()..sort();
      return sorted.join(',');
    }),
  );

  Set<String> packSet(String key) =>
      key.isEmpty ? const <String>{} : key.split(',').toSet();
  final householdPacks = packSet(householdPacksKey);
  final avatarPacks = packSet(avatarPacksKey);

  bool selectable(String? packId, Set<String> entitled) =>
      packId == null || entitled.contains(packId);
  return SelectableCatalog(
    avatars: [
      for (final a in catalog.avatars)
        if (selectable(a.packId, avatarPacks)) a,
    ],
    pictures: [
      for (final p in catalog.pictures)
        if (selectable(p.packId, householdPacks)) p,
    ],
    characters: [
      for (final c in catalog.characters)
        if (selectable(c.packId, householdPacks)) c,
    ],
  );
}

/// Every resolvable row, ungated by which packs a household has applied:
/// general-catalog rows (no pack) plus every row whose pack is enabled.
/// This is the *resolution* set - a chosen avatar/picture/character must
/// render in any household the viewer is in, not just one that redeemed
/// the pack; the picker gating (which packs you may *select* from) lives
/// in [selectableCatalogProvider]. There's no per-row enabled flag - a
/// saved row is live; staging/retiring is done by assigning the row to a
/// disabled pack (the "Vault" trick), and disabling a pack suspends its
/// art everywhere, including already-chosen art.
Future<List<RecordModel>> _rows(PocketBase pb, String collection) {
  return pb.collection(collection).getFullList(
    filter: "pack = '' || pack.enabled = true",
    sort: 'sort_order,created',
  );
}

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
  final pack = r.getStringValue('pack');
  return Avatar(
    id: slug,
    displayName: r.getStringValue('display_name'),
    remoteImage: pb.files.getUrl(r, image),
    packId: pack.isEmpty ? null : pack,
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
  final pack = r.getStringValue('pack');
  return Picture(
    id: slug,
    displayName: r.getStringValue('display_name'),
    remoteVariants: variants,
    packId: pack.isEmpty ? null : pack,
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
  final pack = r.getStringValue('pack');
  return Character(
    id: slug,
    displayName: r.getStringValue('display_name'),
    stageColor: _stageColor(r.getStringValue('base_color')),
    fallbackIcon: Icons.task_alt,
    available: expressions.keys.toSet(),
    remoteExpressions: expressions,
    remoteAward: award.isEmpty ? null : pb.files.getUrl(r, award),
    packId: pack.isEmpty ? null : pack,
    messages: CharacterMessages.fromJson(r.data['messages']),
  );
}

Color _stageColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null || cleaned.length != 6) return AppColors.stageCream;
  return Color(0xFF000000 | value);
}
