import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/fcm_token_sync.dart';
import '../features/nfc/nfc_launch_handler.dart';
import '../router/app_router.dart';
import 'theme.dart';

/// Global key the [NfcLaunchHandler] uses to surface snackbars when the
/// app was opened by an NFC tap and there's no specific screen context.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  NfcLaunchHandler? _nfcLaunch;

  @override
  void initState() {
    super.initState();
    _nfcLaunch = NfcLaunchHandler(ref, rootMessengerKey);
    _nfcLaunch!.start();
  }

  @override
  void dispose() {
    _nfcLaunch?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watching the sync mounts the provider so it stays alive across
    // auth changes and pushes the FCM token to PB whenever it should.
    ref.watch(fcmTokenSyncProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Have You Fed The Dog?',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: lightTheme,
      darkTheme: darkTheme,
      // Follows the phone's light/dark setting — predictable, and the OS
      // handles scheduled/auto dark mode better than we ever would.
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
