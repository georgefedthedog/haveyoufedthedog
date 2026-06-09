// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subjectStreakHash() => r'f386095bbdc733f1f6bc512f2f3346e6454979e8';

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

/// Number of consecutive days (ending today or yesterday) that this
/// subject has at least one completion logged.
///
/// "Today" counts as a streak day once you log anything; "yesterday"
/// keeps the streak alive while you haven't yet logged today's chores.
/// If the latest completion is older than yesterday, the streak is 0.
///
/// Derived from [recentCompletionsControllerProvider] — no extra fetch.
///
/// Copied from [subjectStreak].
@ProviderFor(subjectStreak)
const subjectStreakProvider = SubjectStreakFamily();

/// Number of consecutive days (ending today or yesterday) that this
/// subject has at least one completion logged.
///
/// "Today" counts as a streak day once you log anything; "yesterday"
/// keeps the streak alive while you haven't yet logged today's chores.
/// If the latest completion is older than yesterday, the streak is 0.
///
/// Derived from [recentCompletionsControllerProvider] — no extra fetch.
///
/// Copied from [subjectStreak].
class SubjectStreakFamily extends Family<int> {
  /// Number of consecutive days (ending today or yesterday) that this
  /// subject has at least one completion logged.
  ///
  /// "Today" counts as a streak day once you log anything; "yesterday"
  /// keeps the streak alive while you haven't yet logged today's chores.
  /// If the latest completion is older than yesterday, the streak is 0.
  ///
  /// Derived from [recentCompletionsControllerProvider] — no extra fetch.
  ///
  /// Copied from [subjectStreak].
  const SubjectStreakFamily();

  /// Number of consecutive days (ending today or yesterday) that this
  /// subject has at least one completion logged.
  ///
  /// "Today" counts as a streak day once you log anything; "yesterday"
  /// keeps the streak alive while you haven't yet logged today's chores.
  /// If the latest completion is older than yesterday, the streak is 0.
  ///
  /// Derived from [recentCompletionsControllerProvider] — no extra fetch.
  ///
  /// Copied from [subjectStreak].
  SubjectStreakProvider call(String subjectId) {
    return SubjectStreakProvider(subjectId);
  }

  @override
  SubjectStreakProvider getProviderOverride(
    covariant SubjectStreakProvider provider,
  ) {
    return call(provider.subjectId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'subjectStreakProvider';
}

/// Number of consecutive days (ending today or yesterday) that this
/// subject has at least one completion logged.
///
/// "Today" counts as a streak day once you log anything; "yesterday"
/// keeps the streak alive while you haven't yet logged today's chores.
/// If the latest completion is older than yesterday, the streak is 0.
///
/// Derived from [recentCompletionsControllerProvider] — no extra fetch.
///
/// Copied from [subjectStreak].
class SubjectStreakProvider extends AutoDisposeProvider<int> {
  /// Number of consecutive days (ending today or yesterday) that this
  /// subject has at least one completion logged.
  ///
  /// "Today" counts as a streak day once you log anything; "yesterday"
  /// keeps the streak alive while you haven't yet logged today's chores.
  /// If the latest completion is older than yesterday, the streak is 0.
  ///
  /// Derived from [recentCompletionsControllerProvider] — no extra fetch.
  ///
  /// Copied from [subjectStreak].
  SubjectStreakProvider(String subjectId)
    : this._internal(
        (ref) => subjectStreak(ref as SubjectStreakRef, subjectId),
        from: subjectStreakProvider,
        name: r'subjectStreakProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$subjectStreakHash,
        dependencies: SubjectStreakFamily._dependencies,
        allTransitiveDependencies:
            SubjectStreakFamily._allTransitiveDependencies,
        subjectId: subjectId,
      );

  SubjectStreakProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subjectId,
  }) : super.internal();

  final String subjectId;

  @override
  Override overrideWith(int Function(SubjectStreakRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: SubjectStreakProvider._internal(
        (ref) => create(ref as SubjectStreakRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subjectId: subjectId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _SubjectStreakProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubjectStreakProvider && other.subjectId == subjectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subjectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubjectStreakRef on AutoDisposeProviderRef<int> {
  /// The parameter `subjectId` of this provider.
  String get subjectId;
}

class _SubjectStreakProviderElement extends AutoDisposeProviderElement<int>
    with SubjectStreakRef {
  _SubjectStreakProviderElement(super.provider);

  @override
  String get subjectId => (origin as SubjectStreakProvider).subjectId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
