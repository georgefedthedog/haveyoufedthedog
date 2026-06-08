// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_completions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayCompletionsControllerHash() =>
    r'0d323739f18ab5c0cbc501a9757c6562a0645e38';

/// Completions logged today (local-day) for the current household.
/// Backs the green/grey state of the chore-status chips on the home screen.
///
/// Day boundary is *local* — converted to UTC for the server filter, since
/// PocketBase stores `completed_at` in UTC.
///
/// Copied from [TodayCompletionsController].
@ProviderFor(TodayCompletionsController)
final todayCompletionsControllerProvider =
    AsyncNotifierProvider<
      TodayCompletionsController,
      List<Completion>
    >.internal(
      TodayCompletionsController.new,
      name: r'todayCompletionsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$todayCompletionsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TodayCompletionsController = AsyncNotifier<List<Completion>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
