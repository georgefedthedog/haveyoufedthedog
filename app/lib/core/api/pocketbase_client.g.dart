// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pocketbase_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pocketbaseClientHash() => r'b9625f1d7c46e90d544652495338b040ff9e515a';

/// The app-wide PocketBase client. We do the async initial-token load in
/// `main()` and override this provider with the resulting instance, so
/// everything downstream gets a synchronous `PocketBase`.
///
/// See `main.dart` for the override.
///
/// Copied from [pocketbaseClient].
@ProviderFor(pocketbaseClient)
final pocketbaseClientProvider = Provider<PocketBase>.internal(
  pocketbaseClient,
  name: r'pocketbaseClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pocketbaseClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PocketbaseClientRef = ProviderRef<PocketBase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
