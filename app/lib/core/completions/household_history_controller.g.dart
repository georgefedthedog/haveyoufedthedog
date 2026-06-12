// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$householdHistoryControllerHash() =>
    r'f3a50bed1aa8dbaeacfa85616fe168ceead180b5';

/// Recent completions across every subject in the current household. Used
/// by the History tab. Returns the last `perPage` entries (100 by default
/// - small households' "everything since forever" fits comfortably).
///
/// Copied from [HouseholdHistoryController].
@ProviderFor(HouseholdHistoryController)
final householdHistoryControllerProvider =
    AsyncNotifierProvider<
      HouseholdHistoryController,
      List<Completion>
    >.internal(
      HouseholdHistoryController.new,
      name: r'householdHistoryControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$householdHistoryControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HouseholdHistoryController = AsyncNotifier<List<Completion>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
