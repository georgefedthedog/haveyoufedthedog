// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_voice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bundledCharacterVoicesHash() =>
    r'30309e074b4a03da4bf5df6f4c2ae86b9e98a730';

/// The bundled characters' mood lines in the app's current language, loaded
/// from `assets/l10n/characters/<lang>.json` - a map of character id →
/// [CharacterMessages]-shaped payload (the same shape pack characters carry
/// on `catalog_characters.messages`, so one format serves both pipelines).
///
/// English returns an empty map: the English voice is the const table in
/// `character_message.dart`, which is also the final fallback for any slot
/// a translation file omits. Fail-soft: a missing or malformed asset just
/// means English lines.
///
/// Copied from [bundledCharacterVoices].
@ProviderFor(bundledCharacterVoices)
final bundledCharacterVoicesProvider =
    FutureProvider<Map<String, CharacterMessages>>.internal(
      bundledCharacterVoices,
      name: r'bundledCharacterVoicesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bundledCharacterVoicesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BundledCharacterVoicesRef =
    FutureProviderRef<Map<String, CharacterMessages>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
