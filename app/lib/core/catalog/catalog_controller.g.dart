// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$remoteCatalogHash() => r'5e3c952e411f71dfec4d84bbe1900cc02a8e95bf';

/// Fetches the enabled rows of the three `catalog_*` collections once per
/// session (rebuilds on auth change). **Fail-soft by design:** when the
/// fetch fails - offline, old server without the collections - it falls
/// back to the last successful fetch, persisted as a JSON snapshot in
/// SharedPreferences. Image bytes live in the cached_network_image disk
/// cache, so together the two caches make remote art fully offline-capable
/// after it's been seen once. Only a fresh install that has never reached
/// the server (or a snapshot that fails to parse) degrades to
/// [RemoteCatalog.empty] / bundled-only.
///
/// Copied from [remoteCatalog].
@ProviderFor(remoteCatalog)
final remoteCatalogProvider = FutureProvider<RemoteCatalog>.internal(
  remoteCatalog,
  name: r'remoteCatalogProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteCatalogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RemoteCatalogRef = FutureProviderRef<RemoteCatalog>;
String _$catalogHash() => r'c2c244d3a5793b3e33c7dffd447ce4bfe9b25409';

/// Merged bundled + remote catalog. Synchronous and always usable: starts
/// as bundled-only, re-emits once (if) the remote fetch lands.
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
String _$selectableCatalogHash() => r'1fe9e539797a578eb931ab95205fd6f7d0ef1779';

/// The art the *current* household may select in the pickers - bundled and
/// general-catalog art (always), plus art from the packs that household has
/// applied. Rebuilds on household switch / pack redeem via the packs key.
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
