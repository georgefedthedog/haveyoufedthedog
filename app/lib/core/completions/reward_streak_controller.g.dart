// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_streak_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$householdRewardStreakHash() =>
    r'4fa3aa23c00c255318c5dd074b0bcf40353a4d61';

/// Approximate household-wide reward streak for the streak-unlock progress UI:
/// consecutive **due-days** (any active chore for any subject in the current
/// household) with at least one completion, counting only days *after* the
/// household's last free redemption. Lenient on purpose - the household just
/// has to log *something* on each due day.
///
/// This is **advisory**: the worker recomputes the streak authoritatively
/// (timezone-aware) when a claim is made, so this device-local copy only
/// drives the progress bar and the "claim" affordance. A day-boundary
/// difference at worst shows the claim button an hour early or late.
///
/// Unlike most stats it does its own small fetch rather than reuse the
/// last-100 [householdHistoryControllerProvider] cache: a long streak needs
/// more day-level history than 100 completions covers for a busy household.
/// We pull only the recent window (sorted newest-first, capped at one page),
/// which is the slice the backward walk actually reads.
///
/// Copied from [householdRewardStreak].
@ProviderFor(householdRewardStreak)
final householdRewardStreakProvider = AutoDisposeFutureProvider<int>.internal(
  householdRewardStreak,
  name: r'householdRewardStreakProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$householdRewardStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HouseholdRewardStreakRef = AutoDisposeFutureProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
