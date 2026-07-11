import 'package:flutter/foundation.dart';

/// Author-supplied message overrides for a remote (pack) character, parsed
/// from the `messages` JSON field on `catalog_characters`. Every part is
/// optional and falls back **per slot** to the bundled `generic` copy, so a
/// pack author can override just the moods/strings they care about.
///
/// Bundled characters never carry this (their copy stays hardcoded in
/// `character_message.dart` / `awards_controller.dart`); `Character.messages`
/// is null for them.
@immutable
class CharacterMessages {
  /// Mood name ([SubjectMood.name]) → candidate `(title, body)` lines. A mood
  /// absent here falls back to the bundled table. Keyed by string rather than
  /// the `SubjectMood` enum to keep this file dependency-free (the enum lives
  /// in `character_message.dart`, which imports `character.dart`).
  final Map<String, List<({String title, String body})>> lines;

  /// Override for the character-voiced weekly award title; null = generic.
  final String? awardTitle;

  /// Override for the thank-you line under the featured award; null = generic.
  final String? awardThanks;

  /// Per-language translations of this voice, parsed from a sibling `i18n`
  /// key: `{"lines": {...}, "i18n": {"de": {"lines": {...}}, ...}}`. Keyed
  /// by bare language code. The released (pre-i18n) app's parser reads only
  /// the three keys above, so adding `i18n` to live rows is backward
  /// compatible. Always empty on the nested translations themselves.
  final Map<String, CharacterMessages> translations;

  const CharacterMessages({
    this.lines = const {},
    this.awardTitle,
    this.awardThanks,
    this.translations = const {},
  });

  /// Parses the decoded `messages` JSON value (a `Map`, or anything else /
  /// null). Skips malformed entries defensively and returns null when there's
  /// nothing usable, so callers can `?? <generic fallback>`.
  static CharacterMessages? fromJson(Object? raw) {
    if (raw is! Map) return null;

    final lines = <String, List<({String title, String body})>>{};
    final linesRaw = raw['lines'];
    if (linesRaw is Map) {
      linesRaw.forEach((mood, variants) {
        if (mood is! String || variants is! List) return;
        final parsed = <({String title, String body})>[];
        for (final v in variants) {
          if (v is! Map) continue;
          final title = v['title'];
          final body = v['body'];
          if (title is String && title.isNotEmpty && body is String) {
            parsed.add((title: title, body: body));
          }
        }
        if (parsed.isNotEmpty) lines[mood] = parsed;
      });
    }

    String? str(Object? v) => v is String && v.isNotEmpty ? v : null;
    final awardTitle = str(raw['awardTitle']);
    final awardThanks = str(raw['awardThanks']);

    final translations = <String, CharacterMessages>{};
    final i18nRaw = raw['i18n'];
    if (i18nRaw is Map) {
      i18nRaw.forEach((lang, payload) {
        if (lang is! String || lang.isEmpty) return;
        // A nested i18n inside a translation is ignored by this same parse.
        final parsed = fromJson(payload);
        if (parsed != null) translations[lang] = parsed;
      });
    }

    if (lines.isEmpty &&
        awardTitle == null &&
        awardThanks == null &&
        translations.isEmpty) {
      return null;
    }
    return CharacterMessages(
      lines: lines,
      awardTitle: awardTitle,
      awardThanks: awardThanks,
      translations: translations,
    );
  }
}
