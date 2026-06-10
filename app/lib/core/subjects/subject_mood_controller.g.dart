// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_mood_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subjectMoodHash() => r'c7c2accf11b5b630baaff3ddcbb9a0d8c323ac34';

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

/// How [subjectId] is doing right now — see [SubjectMood] for the
/// priority order. Derived from the chores + today-completions
/// controllers; no extra fetch. Watch this anywhere a subject's state
/// drives UI (hero expression, status copy, card art).
///
/// Copied from [subjectMood].
@ProviderFor(subjectMood)
const subjectMoodProvider = SubjectMoodFamily();

/// How [subjectId] is doing right now — see [SubjectMood] for the
/// priority order. Derived from the chores + today-completions
/// controllers; no extra fetch. Watch this anywhere a subject's state
/// drives UI (hero expression, status copy, card art).
///
/// Copied from [subjectMood].
class SubjectMoodFamily extends Family<SubjectMood> {
  /// How [subjectId] is doing right now — see [SubjectMood] for the
  /// priority order. Derived from the chores + today-completions
  /// controllers; no extra fetch. Watch this anywhere a subject's state
  /// drives UI (hero expression, status copy, card art).
  ///
  /// Copied from [subjectMood].
  const SubjectMoodFamily();

  /// How [subjectId] is doing right now — see [SubjectMood] for the
  /// priority order. Derived from the chores + today-completions
  /// controllers; no extra fetch. Watch this anywhere a subject's state
  /// drives UI (hero expression, status copy, card art).
  ///
  /// Copied from [subjectMood].
  SubjectMoodProvider call(String subjectId) {
    return SubjectMoodProvider(subjectId);
  }

  @override
  SubjectMoodProvider getProviderOverride(
    covariant SubjectMoodProvider provider,
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
  String? get name => r'subjectMoodProvider';
}

/// How [subjectId] is doing right now — see [SubjectMood] for the
/// priority order. Derived from the chores + today-completions
/// controllers; no extra fetch. Watch this anywhere a subject's state
/// drives UI (hero expression, status copy, card art).
///
/// Copied from [subjectMood].
class SubjectMoodProvider extends AutoDisposeProvider<SubjectMood> {
  /// How [subjectId] is doing right now — see [SubjectMood] for the
  /// priority order. Derived from the chores + today-completions
  /// controllers; no extra fetch. Watch this anywhere a subject's state
  /// drives UI (hero expression, status copy, card art).
  ///
  /// Copied from [subjectMood].
  SubjectMoodProvider(String subjectId)
    : this._internal(
        (ref) => subjectMood(ref as SubjectMoodRef, subjectId),
        from: subjectMoodProvider,
        name: r'subjectMoodProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$subjectMoodHash,
        dependencies: SubjectMoodFamily._dependencies,
        allTransitiveDependencies: SubjectMoodFamily._allTransitiveDependencies,
        subjectId: subjectId,
      );

  SubjectMoodProvider._internal(
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
  Override overrideWith(SubjectMood Function(SubjectMoodRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: SubjectMoodProvider._internal(
        (ref) => create(ref as SubjectMoodRef),
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
  AutoDisposeProviderElement<SubjectMood> createElement() {
    return _SubjectMoodProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubjectMoodProvider && other.subjectId == subjectId;
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
mixin SubjectMoodRef on AutoDisposeProviderRef<SubjectMood> {
  /// The parameter `subjectId` of this provider.
  String get subjectId;
}

class _SubjectMoodProviderElement
    extends AutoDisposeProviderElement<SubjectMood>
    with SubjectMoodRef {
  _SubjectMoodProviderElement(super.provider);

  @override
  String get subjectId => (origin as SubjectMoodProvider).subjectId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
