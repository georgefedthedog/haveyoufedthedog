// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localeSyncHash() => r'25675571367847445b8a1016b82c1e8647cd9040';

/// Keeps `users.locale` on PocketBase in step with the language the app is
/// actually showing (device language or the Edit Profile override), so the
/// server can localize pushes. Empty/missing on the server means English -
/// older app builds never write it and keep getting English pushes.
///
/// Mounted (and so kept alive) by `AppRoot` watching this provider.
///
/// Copied from [LocaleSync].
@ProviderFor(LocaleSync)
final localeSyncProvider = AsyncNotifierProvider<LocaleSync, void>.internal(
  LocaleSync.new,
  name: r'localeSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localeSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocaleSync = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
