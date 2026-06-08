// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'households_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$householdsControllerHash() =>
    r'992a5e548460db298ed3b6a7f3c46c615290d346';

/// Loads the current user's households from PocketBase. Each one is joined
/// with the user's `household_members` row to carry role + membershipId.
/// Rebuilds when auth state changes (login / logout / signup).
///
/// Returns an empty list if the user is signed out.
///
/// **State-management notes:**
/// - Both `ref.watch` calls happen *before* any `await`, so Riverpod's
///   dependency tracking stays intact.
/// - We deliberately do two PB calls (memberships → each household) rather
///   than `expand: 'household'`. The expand API in the PB Dart SDK 0.22 has
///   sharp edges (lists vs singletons) we'd rather avoid.
///
/// Copied from [HouseholdsController].
@ProviderFor(HouseholdsController)
final householdsControllerProvider =
    AsyncNotifierProvider<HouseholdsController, List<Household>>.internal(
      HouseholdsController.new,
      name: r'householdsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$householdsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HouseholdsController = AsyncNotifier<List<Household>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
