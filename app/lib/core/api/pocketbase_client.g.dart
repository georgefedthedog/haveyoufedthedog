// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pocketbase_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pocketbaseClientHash() => r'c900560531629b042433d9c981bc3c8316043f2e';

/// Async-initialised PocketBase client. Reads any persisted auth token
/// from secure storage so the user stays signed in across launches.
///
/// Self-contained - no `main()` override dance. Downstream providers
/// `await ref.watch(pocketbaseClientProvider.future)` once and the SDK
/// caches the resolved client for the rest of the session.
///
/// Copied from [pocketbaseClient].
@ProviderFor(pocketbaseClient)
final pocketbaseClientProvider = FutureProvider<PocketBase>.internal(
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
typedef PocketbaseClientRef = FutureProviderRef<PocketBase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
