// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nfc_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nfcServiceHash() => r'd83c5fb4c61eae17562a5a8a20102a2ca59e1dff';

/// Long-lived NFC session wrapper.
///
/// One reader session is started lazily on the first [setHandler] call and
/// reused for the app's lifetime. Handlers can be pushed/restored to support
/// modal scan flows without dropping the home-screen listener.
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
