// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$remoteCatalogHash() => r'dd3e4f3111faf30dfcdb1c1115c405e68f342f0f';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
