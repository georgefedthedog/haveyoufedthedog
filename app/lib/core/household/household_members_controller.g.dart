// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_members_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$householdMembersControllerHash() =>
    r'6679482145a8b751cf66de0314aa206dc2b21502';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$HouseholdMembersController
    extends BuildlessAsyncNotifier<List<HouseholdMember>> {
  late final String householdId;

  FutureOr<List<HouseholdMember>> build(String householdId);
}

/// All members of a given household, with their display names resolved.
///
/// Reads from the `household_member_details` PB View — a server-side JOIN
/// of `household_members` and `users` that exposes only the safe fields
/// (id, household, user, role, user_name). This avoids weakening the
/// `users` collection's security rules.
///
/// Family parameter: the household id.
///
/// **State-management notes:** `ref.watch` happens for both providers
/// synchronously before any `await`. If the View isn't deployed yet the
/// fetch will error and the screen shows it via `AsyncValue.error`.
///
/// Copied from [HouseholdMembersController].
@ProviderFor(HouseholdMembersController)
const householdMembersControllerProvider = HouseholdMembersControllerFamily();

/// All members of a given household, with their display names resolved.
///
/// Reads from the `household_member_details` PB View — a server-side JOIN
/// of `household_members` and `users` that exposes only the safe fields
/// (id, household, user, role, user_name). This avoids weakening the
/// `users` collection's security rules.
///
/// Family parameter: the household id.
///
/// **State-management notes:** `ref.watch` happens for both providers
/// synchronously before any `await`. If the View isn't deployed yet the
/// fetch will error and the screen shows it via `AsyncValue.error`.
///
/// Copied from [HouseholdMembersController].
class HouseholdMembersControllerFamily
    extends Family<AsyncValue<List<HouseholdMember>>> {
  /// All members of a given household, with their display names resolved.
  ///
  /// Reads from the `household_member_details` PB View — a server-side JOIN
  /// of `household_members` and `users` that exposes only the safe fields
  /// (id, household, user, role, user_name). This avoids weakening the
  /// `users` collection's security rules.
  ///
  /// Family parameter: the household id.
  ///
  /// **State-management notes:** `ref.watch` happens for both providers
  /// synchronously before any `await`. If the View isn't deployed yet the
  /// fetch will error and the screen shows it via `AsyncValue.error`.
  ///
  /// Copied from [HouseholdMembersController].
  const HouseholdMembersControllerFamily();

  /// All members of a given household, with their display names resolved.
  ///
  /// Reads from the `household_member_details` PB View — a server-side JOIN
  /// of `household_members` and `users` that exposes only the safe fields
  /// (id, household, user, role, user_name). This avoids weakening the
  /// `users` collection's security rules.
  ///
  /// Family parameter: the household id.
  ///
  /// **State-management notes:** `ref.watch` happens for both providers
  /// synchronously before any `await`. If the View isn't deployed yet the
  /// fetch will error and the screen shows it via `AsyncValue.error`.
  ///
  /// Copied from [HouseholdMembersController].
  HouseholdMembersControllerProvider call(String householdId) {
    return HouseholdMembersControllerProvider(householdId);
  }

  @override
  HouseholdMembersControllerProvider getProviderOverride(
    covariant HouseholdMembersControllerProvider provider,
  ) {
    return call(provider.householdId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'householdMembersControllerProvider';
}

/// All members of a given household, with their display names resolved.
///
/// Reads from the `household_member_details` PB View — a server-side JOIN
/// of `household_members` and `users` that exposes only the safe fields
/// (id, household, user, role, user_name). This avoids weakening the
/// `users` collection's security rules.
///
/// Family parameter: the household id.
///
/// **State-management notes:** `ref.watch` happens for both providers
/// synchronously before any `await`. If the View isn't deployed yet the
/// fetch will error and the screen shows it via `AsyncValue.error`.
///
/// Copied from [HouseholdMembersController].
class HouseholdMembersControllerProvider
    extends
        AsyncNotifierProviderImpl<
          HouseholdMembersController,
          List<HouseholdMember>
        > {
  /// All members of a given household, with their display names resolved.
  ///
  /// Reads from the `household_member_details` PB View — a server-side JOIN
  /// of `household_members` and `users` that exposes only the safe fields
  /// (id, household, user, role, user_name). This avoids weakening the
  /// `users` collection's security rules.
  ///
  /// Family parameter: the household id.
  ///
  /// **State-management notes:** `ref.watch` happens for both providers
  /// synchronously before any `await`. If the View isn't deployed yet the
  /// fetch will error and the screen shows it via `AsyncValue.error`.
  ///
  /// Copied from [HouseholdMembersController].
  HouseholdMembersControllerProvider(String householdId)
    : this._internal(
        () => HouseholdMembersController()..householdId = householdId,
        from: householdMembersControllerProvider,
        name: r'householdMembersControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$householdMembersControllerHash,
        dependencies: HouseholdMembersControllerFamily._dependencies,
        allTransitiveDependencies:
            HouseholdMembersControllerFamily._allTransitiveDependencies,
        householdId: householdId,
      );

  HouseholdMembersControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.householdId,
  }) : super.internal();

  final String householdId;

  @override
  FutureOr<List<HouseholdMember>> runNotifierBuild(
    covariant HouseholdMembersController notifier,
  ) {
    return notifier.build(householdId);
  }

  @override
  Override overrideWith(HouseholdMembersController Function() create) {
    return ProviderOverride(
      origin: this,
      override: HouseholdMembersControllerProvider._internal(
        () => create()..householdId = householdId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        householdId: householdId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<
    HouseholdMembersController,
    List<HouseholdMember>
  >
  createElement() {
    return _HouseholdMembersControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HouseholdMembersControllerProvider &&
        other.householdId == householdId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, householdId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HouseholdMembersControllerRef
    on AsyncNotifierProviderRef<List<HouseholdMember>> {
  /// The parameter `householdId` of this provider.
  String get householdId;
}

class _HouseholdMembersControllerProviderElement
    extends
        AsyncNotifierProviderElement<
          HouseholdMembersController,
          List<HouseholdMember>
        >
    with HouseholdMembersControllerRef {
  _HouseholdMembersControllerProviderElement(super.provider);

  @override
  String get householdId =>
      (origin as HouseholdMembersControllerProvider).householdId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
