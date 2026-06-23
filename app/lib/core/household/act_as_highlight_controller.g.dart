// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act_as_highlight_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$actAsHighlightHash() => r'7a5b8e03fbd96c4cb3c71d970f94bf940b85a359';

/// One-shot signal asking the You tab's "Whose turn?" card to flash itself
/// into view. Set when the home members row taps a managed member (which
/// navigates to the You tab); the card consumes it once it has flashed.
///
/// Kept alive so the flag survives the gap between the tap and the You tab
/// first building - the tab is a lazily-built nav branch, so a plain
/// `ref.listen` would miss a signal raised before it mounts.
///
/// Copied from [ActAsHighlight].
@ProviderFor(ActAsHighlight)
final actAsHighlightProvider = NotifierProvider<ActAsHighlight, bool>.internal(
  ActAsHighlight.new,
  name: r'actAsHighlightProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$actAsHighlightHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActAsHighlight = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
