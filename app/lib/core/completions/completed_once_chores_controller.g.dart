// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_once_chores_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$completedOnceChoreIdsControllerHash() =>
    r'15088ad75fc0005f64137999e1ded7957dcfd15d';

/// Chore ids of one-off (`schedule_type = once`) chores in the current
/// household that have *any* completion. A one-off's first completion is
/// terminal, so membership here means "this one-off is done for good".
///
/// The home screen uses it to retire a finished one-off the day after it's
/// logged: it shows as done on its completion day (via the today-completions
/// list), then this set hides it - covering the gap between local midnight and
/// when the worker flips the chore inactive, so it never flashes back as
/// "pending". Bumped alongside the other read-side lists when a completion is
/// logged or undone.
///
/// Copied from [CompletedOnceChoreIdsController].
@ProviderFor(CompletedOnceChoreIdsController)
final completedOnceChoreIdsControllerProvider =
    AsyncNotifierProvider<
      CompletedOnceChoreIdsController,
      Set<String>
    >.internal(
      CompletedOnceChoreIdsController.new,
      name: r'completedOnceChoreIdsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$completedOnceChoreIdsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CompletedOnceChoreIdsController = AsyncNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
