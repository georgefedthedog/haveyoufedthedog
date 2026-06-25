// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nfc_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nfcServiceHash() => r'282500a68971556318cb4a740d5f2568f9af5f15';

/// Writes our `/nfc-tap` universal links to NFC tags. Reading is no longer
/// done in-app at all - a tap is handled by the OS via the universal link (see
/// [NfcLaunchHandler]); this service only *writes* the tag so families don't
/// need a third-party app.
///
/// Copied from [nfcService].
@ProviderFor(nfcService)
final nfcServiceProvider = Provider<NfcService>.internal(
  nfcService,
  name: r'nfcServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nfcServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NfcServiceRef = ProviderRef<NfcService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
