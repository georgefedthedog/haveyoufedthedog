// Helpers for the catalog's `*_i18n` JSON columns - flat `{lang: text}`
// maps translating a row's display name / description. Additive columns the
// pre-i18n app never reads, so publishing translations is always safe.

/// Defensively parses a decoded `{lang: text}` JSON value. Anything that
/// isn't a map of non-empty strings is dropped.
Map<String, String> nameI18nFromJson(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, String>{};
  raw.forEach((k, v) {
    if (k is String && k.isNotEmpty && v is String && v.isNotEmpty) out[k] = v;
  });
  return out;
}

/// The translation for [localeName] ("de", "de_AT", ...), or null when the
/// map has none - callers fall back to the row's base (English) text.
String? pickLocalized(Map<String, String> i18n, String localeName) {
  if (i18n.isEmpty) return null;
  return i18n[localeName] ?? i18n[localeName.split('_').first];
}
