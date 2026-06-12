import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
@Riverpod(keepAlive: true)
class FcmTokenSync extends _$FcmTokenSync {
  StreamSubscription<String>? _refreshSub;

  @override
  Future<void> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    final pb = await ref.watch(pocketbaseClientProvider.future);

    _refreshSub?.cancel();
    _refreshSub = null;
    ref.onDispose(() => _refreshSub?.cancel());

    if (!auth.isAuthenticated || auth.userId == null) return;
    final userId = auth.userId!;
    final existingToken = auth.user?.data['fcm_token'] as String?;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      // Skip the round-trip if the token already matches - belt and
      // braces against any rebuild that escapes the equality fix in
      // AuthState.
      if (token != null && token != existingToken) {
        await pb.collection('users').update(userId, body: {'fcm_token': token});
      }
    } catch (e) {
      debugPrint('FCM token initial save failed: $e');
    }

    _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) async {
      try {
        await pb.collection('users').update(userId, body: {'fcm_token': token});
      } catch (e) {
        debugPrint('FCM token refresh save failed: $e');
      }
    });
  }
}
