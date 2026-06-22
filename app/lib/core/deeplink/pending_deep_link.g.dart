// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_deep_link.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingDeepLinkControllerHash() =>
    r'e9d7f529efee4d34839704713ba5fb192a808870';

/// Holds the single pending deep link (or null). `keepAlive` so it survives
/// the provider churn of the signed-out -> signed-in transition without being
/// disposed before the link can be replayed.
///
/// Copied from [PendingDeepLinkController].
@ProviderFor(PendingDeepLinkController)
final pendingDeepLinkControllerProvider =
    NotifierProvider<PendingDeepLinkController, PendingDeepLink?>.internal(
      PendingDeepLinkController.new,
      name: r'pendingDeepLinkControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingDeepLinkControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PendingDeepLinkController = Notifier<PendingDeepLink?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
