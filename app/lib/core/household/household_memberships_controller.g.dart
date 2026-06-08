// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_memberships_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$householdMembershipsControllerHash() =>
    r'72314ac19293baab5d17bfcad29659f64a539923';

/// Loads the current user's household memberships from PocketBase. Rebuilds
/// when auth state changes (login / logout / signup).
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
/// Copied from [HouseholdMembershipsController].
@ProviderFor(HouseholdMembershipsController)
final householdMembershipsControllerProvider =
    AsyncNotifierProvider<
      HouseholdMembershipsController,
      List<HouseholdMembership>
    >.internal(
      HouseholdMembershipsController.new,
      name: r'householdMembershipsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$householdMembershipsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HouseholdMembershipsController =
    AsyncNotifier<List<HouseholdMembership>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
