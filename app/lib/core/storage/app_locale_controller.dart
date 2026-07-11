import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_preferences_provider.dart';

part 'app_locale_controller.g.dart';

/// Per-device language override. `null` (the default) means follow the
/// device language; otherwise a supported language code ('en', 'de', ...).
///
/// Lives in SharedPreferences (each phone picks its own language) and is
/// set from the Edit Profile screen. Feeds `MaterialApp.router(locale:)`,
/// which falls back to device-locale resolution when this is null.
@Riverpod(keepAlive: true)
class AppLocaleController extends _$AppLocaleController {
  static const _key = 'app_locale';

  @override
  Future<Locale?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final code = prefs.getString(_key);
    return (code == null || code.isEmpty) ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    state = AsyncData(locale);
  }
}
