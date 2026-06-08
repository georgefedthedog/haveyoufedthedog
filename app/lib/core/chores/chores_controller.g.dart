// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chores_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$choresControllerHash() => r'0efe531341c2bea618b84b2df504674787e05eba';

/// All chores in the current household, across every subject. The home
/// screen filters down to "due today" per-subject when rendering chips —
/// it's a small list and that derivation lives close to the UI.
///
/// One query per household instead of one per subject so the home screen
/// doesn't fan out on N requests.
///
/// Copied from [ChoresController].
@ProviderFor(ChoresController)
final choresControllerProvider =
    AsyncNotifierProvider<ChoresController, List<Chore>>.internal(
      ChoresController.new,
      name: r'choresControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$choresControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ChoresController = AsyncNotifier<List<Chore>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
