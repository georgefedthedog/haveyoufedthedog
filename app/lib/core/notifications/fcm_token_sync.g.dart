// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_token_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fcmTokenSyncHash() => r'be1d28efa361d48ad7d0b945434109ac88741f88';

/// Keeps `users.fcm_token` on PocketBase in step with the current device's
/// Firebase Messaging token. Rebuilds whenever auth state changes:
///
/// - On login: fetches the current token and writes it to the user record.
/// - On token refresh while signed in: writes the new token.
/// - On logout: stops listening; the previous token row stays put — clearing
///   it would need an authenticated PB call we no longer have, and the
///   notify hook tolerates stale/missing tokens.
///
/// Mounted (and so kept alive) by `AppRoot` watching this provider.
///
/// Copied from [FcmTokenSync].
@ProviderFor(FcmTokenSync)
final fcmTokenSyncProvider = AsyncNotifierProvider<FcmTokenSync, void>.internal(
  FcmTokenSync.new,
  name: r'fcmTokenSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fcmTokenSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FcmTokenSync = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
