// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manage_chores_highlight_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$manageChoresHighlightHash() =>
    r'b011a09c2967cdd91569e9c43d344c266816da81';

/// One-shot signal asking the Edit thing screen to flash its "Manage chores"
/// section into view. Set when the "Manage chores" link below a subject's
/// today-list is tapped (which navigates to Edit thing); the section consumes
/// it once it has flashed.
///
/// Kept alive so the flag survives the gap between the tap and Edit thing first
/// building - mirrors NfcSettingHighlight.
///
/// Copied from [ManageChoresHighlight].
@ProviderFor(ManageChoresHighlight)
final manageChoresHighlightProvider =
    NotifierProvider<ManageChoresHighlight, bool>.internal(
      ManageChoresHighlight.new,
      name: r'manageChoresHighlightProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$manageChoresHighlightHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ManageChoresHighlight = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
