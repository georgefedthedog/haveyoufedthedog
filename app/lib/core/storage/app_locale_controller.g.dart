// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_locale_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appLocaleControllerHash() =>
    r'e2df3f8fdb30514b5544f602c60cde646e45d009';

/// Per-device language override. `null` (the default) means follow the
/// device language; otherwise a supported language code ('en', 'de', ...).
///
/// Lives in SharedPreferences (each phone picks its own language) and is
/// set from the Edit Profile screen. Feeds `MaterialApp.router(locale:)`,
/// which falls back to device-locale resolution when this is null.
///
/// Copied from [AppLocaleController].
@ProviderFor(AppLocaleController)
final appLocaleControllerProvider =
    AsyncNotifierProvider<AppLocaleController, Locale?>.internal(
      AppLocaleController.new,
      name: r'appLocaleControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appLocaleControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AppLocaleController = AsyncNotifier<Locale?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
