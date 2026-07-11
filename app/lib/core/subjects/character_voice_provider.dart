import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_localizations_provider.dart';
import 'character_messages.dart';

part 'character_voice_provider.g.dart';

/// The bundled characters' mood lines in the app's current language, loaded
/// from `assets/l10n/characters/<lang>.json` - a map of character id →
/// [CharacterMessages]-shaped payload (the same shape pack characters carry
/// on `catalog_characters.messages`, so one format serves both pipelines).
///
/// English returns an empty map: the English voice is the const table in
/// `character_message.dart`, which is also the final fallback for any slot
/// a translation file omits. Fail-soft: a missing or malformed asset just
/// means English lines.
@Riverpod(keepAlive: true)
Future<Map<String, CharacterMessages>> bundledCharacterVoices(Ref ref) async {
  final lang = ref.watch(appLocalizationsProvider).localeName.split('_').first;
  if (lang == 'en') return const {};

  final out = <String, CharacterMessages>{};
  try {
    final raw = await rootBundle.loadString(
      'assets/l10n/characters/$lang.json',
    );
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      decoded.forEach((id, payload) {
        if (id is! String) return;
        final parsed = CharacterMessages.fromJson(payload);
        if (parsed != null) out[id] = parsed;
      });
    }
  } catch (_) {
    // No asset for this language (or malformed) - English fallback.
  }
  return out;
}
