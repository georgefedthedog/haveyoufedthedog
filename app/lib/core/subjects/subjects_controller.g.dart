// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subjectsControllerHash() =>
    r'220929fc8bcfee2f2fe96131dadb131e2f04d0ab';

/// Loads the current household's subjects from PocketBase. Rebuilds whenever
/// the user switches household.
///
/// Returns an empty list if no household is currently selected.
///
/// Copied from [SubjectsController].
@ProviderFor(SubjectsController)
final subjectsControllerProvider =
    AsyncNotifierProvider<SubjectsController, List<Subject>>.internal(
      SubjectsController.new,
      name: r'subjectsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$subjectsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SubjectsController = AsyncNotifier<List<Subject>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
