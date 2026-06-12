// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentWeekStatsHash() => r'f284f096eb74f4dc82e751530112942236eae98a';

/// Stats for the current ISO week (Mon → Sun, local clock). Derived from
/// [householdHistoryControllerProvider]; no extra fetch.
///
/// Copied from [currentWeekStats].
@ProviderFor(currentWeekStats)
final currentWeekStatsProvider = AutoDisposeProvider<WeeklyStats>.internal(
  currentWeekStats,
  name: r'currentWeekStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentWeekStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentWeekStatsRef = AutoDisposeProviderRef<WeeklyStats>;
String _$previousWeekStatsHash() => r'177d9fea5e6ef20500b5607116ac7edb3d373fb8';

/// Stats for last week - used for the week-over-week delta on the History
/// tab. Same data source.
///
/// Copied from [previousWeekStats].
@ProviderFor(previousWeekStats)
final previousWeekStatsProvider = AutoDisposeProvider<WeeklyStats>.internal(
  previousWeekStats,
  name: r'previousWeekStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$previousWeekStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PreviousWeekStatsRef = AutoDisposeProviderRef<WeeklyStats>;
String _$choreMeanTimesHash() => r'04202d2dc625df8ffa2300a35466405f7acec45b';

/// Mean completion time-of-day per chore id, derived from the cached
/// household history. Uses a circular mean (angles on a 24h clock face)
/// so a chore done at 11pm and 1am averages to midnight, not noon.
/// Chores with fewer than two logged completions are omitted - one data
/// point isn't a habit yet.
///
/// Copied from [choreMeanTimes].
@ProviderFor(choreMeanTimes)
final choreMeanTimesProvider =
    AutoDisposeProvider<Map<String, TimeOfDay>>.internal(
      choreMeanTimes,
      name: r'choreMeanTimesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$choreMeanTimesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChoreMeanTimesRef = AutoDisposeProviderRef<Map<String, TimeOfDay>>;
String _$householdStreakHash() => r'082233c31088f1b2fc01413e01df14347da96a03';

/// Number of consecutive **due days** with at least one completion,
/// household-wide. Same schedule-aware walk as `subjectStreakProvider`:
/// days where no chore in the household is due are skipped (they neither
/// count nor break), and today gets a grace pass while its chores are
/// still outstanding.
///
/// Copied from [householdStreak].
@ProviderFor(householdStreak)
final householdStreakProvider = AutoDisposeProvider<int>.internal(
  householdStreak,
  name: r'householdStreakProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$householdStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HouseholdStreakRef = AutoDisposeProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
