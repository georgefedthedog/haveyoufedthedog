// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_completions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentCompletionsControllerHash() =>
    r'7679ba452a6d73c6a7c6641bf52b4793bc01ae69';

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

abstract class _$RecentCompletionsController
    extends BuildlessAsyncNotifier<List<Completion>> {
  late final String subjectId;

  FutureOr<List<Completion>> build(String subjectId);
}

/// Recent completions for one subject - backs the history list on the
/// subject detail screen. Family parameter: the subject id.
///
/// Uses `getList` with `perPage: 50` rather than `getFullList` - we don't
/// need every completion ever, just the recent ones. If history grows huge
/// we can paginate later.
///
/// Copied from [RecentCompletionsController].
@ProviderFor(RecentCompletionsController)
const recentCompletionsControllerProvider = RecentCompletionsControllerFamily();

/// Recent completions for one subject - backs the history list on the
/// subject detail screen. Family parameter: the subject id.
///
/// Uses `getList` with `perPage: 50` rather than `getFullList` - we don't
/// need every completion ever, just the recent ones. If history grows huge
/// we can paginate later.
///
/// Copied from [RecentCompletionsController].
class RecentCompletionsControllerFamily
    extends Family<AsyncValue<List<Completion>>> {
  /// Recent completions for one subject - backs the history list on the
  /// subject detail screen. Family parameter: the subject id.
  ///
  /// Uses `getList` with `perPage: 50` rather than `getFullList` - we don't
  /// need every completion ever, just the recent ones. If history grows huge
  /// we can paginate later.
  ///
  /// Copied from [RecentCompletionsController].
  const RecentCompletionsControllerFamily();

  /// Recent completions for one subject - backs the history list on the
  /// subject detail screen. Family parameter: the subject id.
  ///
  /// Uses `getList` with `perPage: 50` rather than `getFullList` - we don't
  /// need every completion ever, just the recent ones. If history grows huge
  /// we can paginate later.
  ///
  /// Copied from [RecentCompletionsController].
  RecentCompletionsControllerProvider call(String subjectId) {
    return RecentCompletionsControllerProvider(subjectId);
  }

  @override
  RecentCompletionsControllerProvider getProviderOverride(
    covariant RecentCompletionsControllerProvider provider,
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
  String? get name => r'recentCompletionsControllerProvider';
}

/// Recent completions for one subject - backs the history list on the
/// subject detail screen. Family parameter: the subject id.
///
/// Uses `getList` with `perPage: 50` rather than `getFullList` - we don't
/// need every completion ever, just the recent ones. If history grows huge
/// we can paginate later.
///
/// Copied from [RecentCompletionsController].
class RecentCompletionsControllerProvider
    extends
        AsyncNotifierProviderImpl<
          RecentCompletionsController,
          List<Completion>
        > {
  /// Recent completions for one subject - backs the history list on the
  /// subject detail screen. Family parameter: the subject id.
  ///
  /// Uses `getList` with `perPage: 50` rather than `getFullList` - we don't
  /// need every completion ever, just the recent ones. If history grows huge
  /// we can paginate later.
  ///
  /// Copied from [RecentCompletionsController].
  RecentCompletionsControllerProvider(String subjectId)
    : this._internal(
        () => RecentCompletionsController()..subjectId = subjectId,
        from: recentCompletionsControllerProvider,
        name: r'recentCompletionsControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recentCompletionsControllerHash,
        dependencies: RecentCompletionsControllerFamily._dependencies,
        allTransitiveDependencies:
            RecentCompletionsControllerFamily._allTransitiveDependencies,
        subjectId: subjectId,
      );

  RecentCompletionsControllerProvider._internal(
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
  FutureOr<List<Completion>> runNotifierBuild(
    covariant RecentCompletionsController notifier,
  ) {
    return notifier.build(subjectId);
  }

  @override
  Override overrideWith(RecentCompletionsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: RecentCompletionsControllerProvider._internal(
        () => create()..subjectId = subjectId,
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
  AsyncNotifierProviderElement<RecentCompletionsController, List<Completion>>
  createElement() {
    return _RecentCompletionsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentCompletionsControllerProvider &&
        other.subjectId == subjectId;
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
mixin RecentCompletionsControllerRef
    on AsyncNotifierProviderRef<List<Completion>> {
  /// The parameter `subjectId` of this provider.
  String get subjectId;
}

class _RecentCompletionsControllerProviderElement
    extends
        AsyncNotifierProviderElement<
          RecentCompletionsController,
          List<Completion>
        >
    with RecentCompletionsControllerRef {
  _RecentCompletionsControllerProviderElement(super.provider);

  @override
  String get subjectId =>
      (origin as RecentCompletionsControllerProvider).subjectId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
