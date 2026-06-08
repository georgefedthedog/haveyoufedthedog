// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_household_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentHouseholdControllerHash() =>
    r'8b42f3441c4151ec2f3445d9139bbb8fb92a4da9';

/// Picks the currently-active household for the signed-in user.
///
/// Async — consistent with the rest of the data-fetching controllers. The
/// router's `routingPhase` provider buffers this controller's transient
/// `AsyncLoading` states so deep state churn doesn't bounce the user off
/// the screen they're on.
///
/// Resolution rules:
/// - If a persisted household ID is in the user's current memberships, use it.
/// - If the persisted ID is no longer valid, clear it and fall back.
/// - If there's exactly one membership, auto-select it and persist.
/// - Otherwise (0 memberships, or 2+ with no valid persisted choice) return
///   `null` and let the router send the user to setup or picker.
///
/// Copied from [CurrentHouseholdController].
@ProviderFor(CurrentHouseholdController)
final currentHouseholdControllerProvider =
    AsyncNotifierProvider<
      CurrentHouseholdController,
      HouseholdMembership?
    >.internal(
      CurrentHouseholdController.new,
      name: r'currentHouseholdControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentHouseholdControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentHouseholdController = AsyncNotifier<HouseholdMembership?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
