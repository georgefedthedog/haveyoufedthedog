// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routing_phase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routingPhaseHash() => r'0048ca2fe3ad7f8379084c6b5b99d874aecc95ff';

/// Derives the current [RoutingPhase] from auth + memberships + current.
///
/// Returns an enum value, so the router's listener only fires on actual
/// phase transitions. Adding a chore, renaming a household, etc. won't
/// produce a different phase — so the router doesn't bounce the user.
///
/// Copied from [routingPhase].
@ProviderFor(routingPhase)
final routingPhaseProvider = Provider<RoutingPhase>.internal(
  routingPhase,
  name: r'routingPhaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$routingPhaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RoutingPhaseRef = ProviderRef<RoutingPhase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
