// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nfc_setting_highlight_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nfcSettingHighlightHash() =>
    r'7e678aa29d7220e181f5f4909c3839861ffa8384';

/// One-shot signal asking the You tab's NFC card to flash its "Complete chore
/// on tap" setting into view. Set when the "the You tab" link in a subject's
/// NFC-tag card is tapped (which navigates to the You tab); the setting card
/// consumes it once it has flashed.
///
/// Kept alive so the flag survives the gap between the tap and the You tab
/// first building - mirrors [ActAsHighlight] for the Home→You cue.
///
/// Copied from [NfcSettingHighlight].
@ProviderFor(NfcSettingHighlight)
final nfcSettingHighlightProvider =
    NotifierProvider<NfcSettingHighlight, bool>.internal(
      NfcSettingHighlight.new,
      name: r'nfcSettingHighlightProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$nfcSettingHighlightHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NfcSettingHighlight = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
