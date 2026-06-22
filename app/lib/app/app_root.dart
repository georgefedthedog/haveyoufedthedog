import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/deeplink/pending_deep_link.dart';
import '../core/notifications/fcm_token_sync.dart';
import '../core/store/purchase_controller.dart';
import '../features/deeplink/deep_link_handler.dart';
import '../features/nfc/nfc_launch_handler.dart';
import '../router/app_router.dart';
import '../router/routes.dart';
import '../router/routing_phase.dart';
import '../widgets/app_backdrop.dart';
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
  DeepLinkHandler? _deepLink;

  @override
  void initState() {
    super.initState();
    _nfcLaunch = NfcLaunchHandler(ref, rootMessengerKey);
    _nfcLaunch!.start();
    _deepLink = DeepLinkHandler(ref);
    _deepLink!.start();
  }

  @override
  void dispose() {
    _nfcLaunch?.stop();
    _deepLink?.stop();
    super.dispose();
  }

  /// Acts on a captured deep link once the routing phase allows it.
  ///
  /// [DeepLinkHandler] only parks the link (it can't know the phase at
  /// cold-start). This is the one place that turns a pending link into
  /// navigation, so it re-reads fresh state on every phase/link change:
  ///  - signed out: do nothing - the redirect parks the user on `/auth`,
  ///    where a *claim* link is consumed by `AuthLandingScreen`, and a *join*
  ///    link waits here until the user authenticates;
  ///  - signed in (`needsToPick`/`ready`): a *join* link opens the Join form
  ///    pre-filled; a *claim* link is rejected (claiming is a fresh sign-up).
  void _consumePendingDeepLink() {
    final pending = ref.read(pendingDeepLinkControllerProvider);
    if (pending == null) return;
    switch (ref.read(routingPhaseProvider)) {
      case RoutingPhase.loading:
      case RoutingPhase.signedOut:
        return; // wait - consumed downstream or after authentication
      case RoutingPhase.needsToPick:
      case RoutingPhase.ready:
        final notifier = ref.read(pendingDeepLinkControllerProvider.notifier);
        switch (pending.kind) {
          case DeepLinkKind.join:
            ref.read(appRouterProvider).push(_joinLocation(pending.code));
          case DeepLinkKind.claim:
            // TODO(deeplink-claim-ux): a long auto-dismissing snackbar is the
            // wrong surface for this much text. Revisit - likely a persistent
            // dialog with the delete-and-start-over vs. join-link options.
            rootMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                showCloseIcon: true,
                duration: Duration(seconds: 6),
                content: Text(
                  "You're already signed in. To claim an account you must sign up with the claim code. If you have "
                  "just created this account and have no other households it may be best to delete this account and "
                  "start over with the claim code sign up link. If you need to keep this account, ask the household "
                  "owner to send you the link to join the household instead.",
                ),
              ),
            );
        }
        notifier.clear();
    }
  }

  static String _joinLocation(String code) => code.isEmpty
      ? Routes.householdJoin
      : '${Routes.householdJoin}?code=${Uri.encodeQueryComponent(code)}';

  @override
  Widget build(BuildContext context) {
    // Watching the sync mounts the provider so it stays alive across
    // auth changes and pushes the FCM token to PB whenever it should.
    ref.watch(fcmTokenSyncProvider);

    // Mount the purchase controller for the app's lifetime so out-of-band
    // purchase completions (slow card auth, Restore) are always handled.
    ref.watch(purchaseControllerProvider);

    // A deep link can land either before or after the routing phase settles,
    // so react to whichever changes last. `_consumePendingDeepLink` is
    // idempotent (it clears what it acts on), so a double fire is harmless.
    ref.listen(pendingDeepLinkControllerProvider, (_, next) {
      if (next != null) _consumePendingDeepLink();
    });
    ref.listen(routingPhaseProvider, (_, _) => _consumePendingDeepLink());

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Have You Fed The Dog?',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: lightTheme,
      darkTheme: darkTheme,
      // Follows the phone's light/dark setting - predictable, and the OS
      // handles scheduled/auto dark mode better than we ever would.
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          AppBackdrop(child: child ?? const SizedBox.shrink()),
      routerConfig: router,
    );
  }
}
