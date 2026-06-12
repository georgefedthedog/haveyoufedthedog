// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nfc_tap_action_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nfcTapActionControllerHash() =>
    r'f252faffdeb556e59fab7bb4c027af6246d05b00';

/// Per-device preference for what an NFC tag tap does:
///
/// - **true** (default) - complete the closest due chore for the bound
///   subject, with the celebration overlay. The original behaviour.
/// - **false** - just open the subject's detail screen.
///
/// Lives in SharedPreferences (each phone configures its own tap
/// behaviour) and is toggled from the Edit Profile screen.
///
/// Copied from [NfcTapActionController].
@ProviderFor(NfcTapActionController)
final nfcTapActionControllerProvider =
    AsyncNotifierProvider<NfcTapActionController, bool>.internal(
      NfcTapActionController.new,
      name: r'nfcTapActionControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$nfcTapActionControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NfcTapActionController = AsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
