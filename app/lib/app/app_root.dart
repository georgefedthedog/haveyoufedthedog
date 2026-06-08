import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/fcm_token_sync.dart';
import '../router/app_router.dart';
import 'theme.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the sync mounts the provider so it stays alive across
    // auth changes and pushes the FCM token to PB whenever it should.
    ref.watch(fcmTokenSyncProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Have You Fed The Dog?',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: router,
    );
  }
}
