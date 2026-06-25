import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';

part 'fcm_token_sync.g.dart';

/// TEMPORARY on-device diagnostics for the iOS push-token chain. Each stage of
/// [FcmTokenSync] appends a line here; the Edit Profile screen renders it (with
/// a copy button) so we can see, on a TestFlight phone with no console, exactly
/// where token registration breaks. Remove once iOS push is confirmed healthy.
final fcmDebugLog = ValueNotifier<List<String>>(const []);
final _started = DateTime.now();

void _log(String message) {
  final secs = DateTime.now().difference(_started).inMilliseconds / 1000;
  final line = '[+${secs.toStringAsFixed(1)}s] $message';
  debugPrint('FCM: $line');
  fcmDebugLog.value = [...fcmDebugLog.value, line];
}

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

    _log('sync build, userId=${userId == null ? "null (signed out)" : "ok"}');
    if (userId == null) return;
    final existingToken =
        ref.read(authControllerProvider).valueOrNull?.user?.data['fcm_token']
            as String?;

    try {
      // Where does the OS think we stand on notification permission? If this
      // is denied / notDetermined, APNs never registers and no token appears.
      try {
        final settings = await FirebaseMessaging.instance
            .getNotificationSettings();
        _log('authStatus=${settings.authorizationStatus.name}');
      } catch (e) {
        _log('getNotificationSettings threw: $e');
      }

      // iOS only mints an FCM token once the APNs device token has been
      // registered and handed to Firebase. getToken() returns null (or
      // throws apns-token-not-set) before that, and this provider mounts
      // the moment auth resolves - well before notificationService.init()
      // has triggered APNs registration. Poll getAPNSToken() until it
      // lands so we don't ask for the FCM token too early and silently
      // save nothing. (onTokenRefresh below stays as the ongoing net.)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apns;
        for (var i = 0; i < 15; i++) {
          try {
            apns = await FirebaseMessaging.instance.getAPNSToken();
          } catch (e) {
            _log('getAPNSToken threw: $e');
          }
          if (apns != null) break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        _log(
          apns == null
              ? 'APNs token: null after 15s'
              : 'APNs token: got (${apns.length} chars)',
        );
      }

      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        _log('getToken threw: $e');
      }
      _log(
        token == null
            ? 'getToken: null'
            : 'getToken: ${token.substring(0, token.length.clamp(0, 12))}...',
      );

      // Skip the round-trip if the token already matches - belt and
      // braces against any rebuild that escapes the equality fix in
      // AuthState.
      if (token != null && token != existingToken) {
        await pb.collection('users').update(userId, body: {'fcm_token': token});
        _log('saved token to PB');
      } else if (token != null) {
        _log('token unchanged, skipped save');
      }
    } catch (e) {
      _log('ERROR during initial save: $e');
    }

    _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) async {
      _log('onTokenRefresh fired (${token.length} chars)');
      try {
        await pb.collection('users').update(userId, body: {'fcm_token': token});
        _log('saved refreshed token to PB');
      } catch (e) {
        _log('ERROR saving refreshed token: $e');
      }
    });
  }
}
