// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storeProductsHash() => r'b68ec4a16a170d3181fd2d626deb4fcfd0119763';

/// The products for sale: enabled `catalog_products` rows merged with their
/// live store listings.
///
/// **A product only appears if the store also knows its SKU** - so until the
/// Play / App Store products are configured and approved, this is empty even
/// though the PB rows exist. Fail-soft: a store that's unavailable (no
/// billing, offline, signed out) yields an empty list rather than an error,
/// so the storefront just shows "nothing for sale" instead of breaking.
///
/// autoDispose (default): refetched each time the store screen opens so prices
/// and availability stay current.
///
/// Copied from [storeProducts].
@ProviderFor(storeProducts)
final storeProductsProvider =
    AutoDisposeFutureProvider<List<StoreProduct>>.internal(
      storeProducts,
      name: r'storeProductsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$storeProductsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StoreProductsRef = AutoDisposeFutureProviderRef<List<StoreProduct>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
