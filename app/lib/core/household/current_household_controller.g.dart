// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_household_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentHouseholdControllerHash() =>
    r'aa3a8b8a0b9b90ed736e4a28e343e6595d6926a1';

/// Picks the currently-active household for the signed-in user.
///
/// Resolution rules:
/// - If a persisted household ID is in the user's current membership list,
///   that one wins.
/// - If the persisted ID is no longer valid (e.g. household deleted, user
///   removed) we clear it and fall back to the other rules.
/// - If there is exactly one membership, auto-select it and persist.
/// - Otherwise (0 memberships, or 2+ with no valid persisted choice) we
///   return `null` so the router can send the user to setup or the picker.
///
/// **State-management notes:** the only `ref.watch` is `householdMemberships
/// ControllerProvider.future`, called synchronously before any other `await`,
/// so dependency tracking stays clean. `setCurrent` and `clear` use
/// `ref.read` because they're imperative methods, not part of `build()`.
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
