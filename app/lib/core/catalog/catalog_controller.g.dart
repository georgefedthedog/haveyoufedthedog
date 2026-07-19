// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$catalogHash() => r'918c407623990bfc1e6ca84a0eb15edd42a0379d';

/// Merged bundled + remote catalog. Synchronous and always usable: starts
/// as bundled-only, re-emits as soon as the snapshot (then the live fetch)
/// lands. Warmed from `AppRoot` so the snapshot is in place while the
/// splash is still up - screens never see the bundled-only frame.
///
/// Copied from [catalog].
@ProviderFor(catalog)
final catalogProvider = Provider<Catalog>.internal(
  catalog,
  name: r'catalogProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$catalogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CatalogRef = ProviderRef<Catalog>;
String _$selectableCatalogHash() => r'890f7731616124c430909331d0affcf1c308aa2a';

/// The art a user may select in the pickers - bundled and general-catalog
/// art (always), plus packed art they're entitled to. Entitlement differs
/// by art *kind*, matching what each thing belongs to:
///
/// - **Avatars** are personal, so they're gated by the *union* of packs
///   across all the user's households - a packed avatar can be chosen from
///   any household once any of the user's households has the pack.
/// - **Pictures** and **characters** belong to a household, so they're gated
///   by the *current* household's packs only - *plus* any the household has
///   streak-unlocked by slug (a pack-independent grant; see
///   `unlockedCharacterIds` / `unlockedPictureIds`).
///
/// This is the entitlement gate that used to live in the catalog fetch
/// itself. Rendering (resolving any chosen id) goes through [catalogProvider]
/// instead, which is deliberately ungated so chosen art travels across the
/// user's households. Disabled-pack art is already absent from [catalog]
/// (the fetch drops it), so it can't leak into the picker here either.
///
/// Copied from [selectableCatalog].
@ProviderFor(selectableCatalog)
final selectableCatalogProvider = Provider<SelectableCatalog>.internal(
  selectableCatalog,
  name: r'selectableCatalogProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectableCatalogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelectableCatalogRef = ProviderRef<SelectableCatalog>;
String _$remoteCatalogControllerHash() =>
    r'4ce16089297b2c34cc77d5c3215b1462d6a0323b';

/// Fetches the enabled rows of the three `catalog_*` collections once per
/// session (rebuilds on auth change). **Snapshot-first:** every successful
/// fetch is persisted as a JSON snapshot in SharedPreferences, and on the
/// next start the snapshot is served *immediately* while the live fetch
/// refreshes in the background - so chosen remote art (house picture,
/// avatars, characters) resolves on the very first frame instead of
/// flashing the bundled defaults until the network answers. Image bytes
/// live in the cached_network_image disk cache, so together the two caches
/// also make remote art fully offline-capable after it's been seen once
/// (a failed refresh just keeps the snapshot). Only a fresh install that
/// has never reached the server (or a snapshot that fails to parse)
/// degrades to [RemoteCatalog.empty] / bundled-only.
///
/// Copied from [RemoteCatalogController].
@ProviderFor(RemoteCatalogController)
final remoteCatalogControllerProvider =
    AsyncNotifierProvider<RemoteCatalogController, RemoteCatalog>.internal(
      RemoteCatalogController.new,
      name: r'remoteCatalogControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$remoteCatalogControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RemoteCatalogController = AsyncNotifier<RemoteCatalog>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
