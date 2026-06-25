import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';

part 'fcm_token_sync.g.dart';

/// Keeps `users.fcm_token` on PocketBase in step with the current device's
/// Firebase Messaging token. Rebuilds whenever auth state changes:
///
/// - On login: fetches the current token and writes it to the user record.
/// - On token refresh while signed in: writes the new token.
/// - On logout: stops listening; the previous token row stays put - clearing
///   it would need an authenticated PB call we no longer have, and the
///   notify hook tolerates stale/missing tokens.
///
/// Mounted (and so kept alive) by `AppRoot` watching this provider.
///
/// The `FCM:` debugPrint lines below are captured into the on-device debug-log
/// card (see `core/diagnostics/debug_log.dart`).
@Riverpod(keepAlive: true)
class FcmTokenSync extends _$FcmTokenSync {
  StreamSubscription<String>? _refreshSub;

  @override
  Future<void> build() async {
    // Identity-scoped watch: rebuilding on every auth emission would
    // re-fire this for our own fcm_token write (the original infinite
    // loop). Selecting the user id means we rebuild on login/logout only.
    final userId = await ref.watch(
      authControllerProvider.selectAsync((a) => a.userId),
    );
    final pb = await ref.watch(pocketbaseClientProvider.future);

    _refreshSub?.cancel();
    _refreshSub = null;
    ref.onDispose(() => _refreshSub?.cancel());

    debugPrint('FCM: sync build, userId=${userId == null ? "null" : "ok"}');
    if (userId == null) return;
    final existingToken =
        ref.read(authControllerProvider).valueOrNull?.user?.data['fcm_token']
            as String?;

    try {
      try {
        final settings = await FirebaseMessaging.instance
            .getNotificationSettings();
        debugPrint('FCM: authStatus=${settings.authorizationStatus.name}');
      } catch (e) {
        debugPrint('FCM: getNotificationSettings threw: $e');
      }

      // iOS only mints an FCM token once the APNs device token has been
      // registered and handed to Firebase. getToken() returns null (or
      // throws apns-token-not-set) before that, so poll getAPNSToken()
      // until it lands. (onTokenRefresh below stays as the ongoing net.)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apns;
        for (var i = 0; i < 15; i++) {
          try {
            apns = await FirebaseMessaging.instance.getAPNSToken();
          } catch (e) {
            debugPrint('FCM: getAPNSToken threw: $e');
          }
          if (apns != null) break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        debugPrint(
          apns == null
              ? 'FCM: APNs token null after 15s'
              : 'FCM: APNs token got (${apns.length} chars)',
        );

        // Surface the native AppDelegate breadcrumbs (didRegister / didFail /
        // configure) recorded into shared_preferences.
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.reload();
          debugPrint(
            'FCM native: ${prefs.getString('fcm_native_diag') ?? '(none)'}',
          );
        } catch (e) {
          debugPrint('FCM: native diag read failed: $e');
        }
      }

      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('FCM: getToken threw: $e');
      }
      debugPrint(
        token == null
            ? 'FCM: getToken null'
            : 'FCM: getToken ${token.substring(0, token.length.clamp(0, 12))}...',
      );

      if (token != null && token != existingToken) {
        await pb.collection('users').update(userId, body: {'fcm_token': token});
        debugPrint('FCM: saved token to PB');
      } else if (token != null) {
        debugPrint('FCM: token unchanged, skipped save');
      }
    } catch (e) {
      debugPrint('FCM: ERROR during initial save: $e');
    }

    _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) async {
      debugPrint('FCM: onTokenRefresh fired (${token.length} chars)');
      try {
        await pb.collection('users').update(userId, body: {'fcm_token': token});
        debugPrint('FCM: saved refreshed token to PB');
      } catch (e) {
        debugPrint('FCM: ERROR saving refreshed token: $e');
      }
    });
  }
}
