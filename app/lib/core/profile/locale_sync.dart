import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import '../l10n/app_localizations_provider.dart';

part 'locale_sync.g.dart';

/// Keeps `users.locale` on PocketBase in step with the language the app is
/// actually showing (device language or the Edit Profile override), so the
/// server can localize pushes. Empty/missing on the server means English -
/// older app builds never write it and keep getting English pushes.
///
/// Mounted (and so kept alive) by `AppRoot` watching this provider.
@Riverpod(keepAlive: true)
class LocaleSync extends _$LocaleSync {
  @override
  Future<void> build() async {
    // Identity-scoped watch (see FcmTokenSync): rebuild on login/logout
    // only, not on every auth emission - our own write would loop.
    final userId = await ref.watch(
      authControllerProvider.selectAsync((a) => a.userId),
    );
    // The resolved app language ('en', 'de', ...) - already clamped to the
    // supported set with an English fallback. Watching it re-syncs on an
    // Edit Profile language change; a device-language change relaunches
    // the app, which re-syncs on the way up.
    final code = ref.watch(appLocalizationsProvider).localeName;
    if (userId == null) return;

    final stored =
        ref.read(authControllerProvider).valueOrNull?.user?.data['locale']
            as String?;
    if ((stored ?? '') == code) {
      debugPrint('Locale: "$code" already on PB, skipped save');
      return;
    }

    final pb = await ref.watch(pocketbaseClientProvider.future);
    try {
      await pb.collection('users').update(userId, body: {'locale': code});
      debugPrint('Locale: saved "$code" to PB');
    } catch (e) {
      debugPrint('Locale: ERROR saving: $e');
    }
  }
}
