import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_root.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A Firebase init failure must not brick launch - the app is fully usable
  // (sign in, log chores) without push. Surface it and carry on.
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    _reportStartupError('Firebase init failed: $e', st);
  }

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AppRoot(),
    ),
  );

  // Notification setup must NOT gate the first frame. On iOS the FCM calls
  // (requestPermission / getInitialMessage) wait on APNs token registration,
  // which can hang indefinitely - awaiting it before runApp froze the app on
  // the native launch screen. Kick it off after the UI is up; the provider
  // stays alive via `keepAlive: true`. Errors here never block the app.
  unawaited(
    container.read(notificationServiceProvider).init().catchError((
      Object e,
      StackTrace st,
    ) {
      _reportStartupError('Notification init failed: $e', st);
    }),
  );
}

/// Surfaces a caught startup failure where it can actually be seen on a
/// release/TestFlight build (debugPrint vanishes without a Mac attached):
/// a snackbar on the app's global messenger, on whatever screen is up.
///
/// Temporary diagnostic - replace with real telemetry (e.g. Crashlytics)
/// once the iOS launch path is confirmed healthy. Retries briefly because
/// the messenger isn't attached until the first frame builds.
void _reportStartupError(String message, [StackTrace? st]) {
  debugPrint('$message\n${st ?? ''}');

  Future<void> show([int attempt = 0]) async {
    final messenger = rootMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          duration: const Duration(seconds: 10),
          content: Text(message),
        ),
      );
      return;
    }
    if (attempt >= 10) return; // UI never came up - nothing we can do
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return show(attempt + 1);
  }

  unawaited(show());
}
