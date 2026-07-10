import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../core/deeplink/pending_deep_link.dart';
import '../core/notifications/fcm_token_sync.dart';
import '../core/store/purchase_controller.dart';
import '../features/deeplink/claim_signed_in_dialog.dart';
import '../features/deeplink/deep_link_handler.dart';
import '../features/nfc/nfc_launch_handler.dart';
import '../router/app_router.dart';
import '../router/routes.dart';
import '../router/routing_phase.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/confirm_by_typing.dart';
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

  /// Guards against re-entering the signed-in claim dialog while it's open.
  bool _handlingClaim = false;

  @override
  void initState() {
    super.initState();
    _nfcLaunch = NfcLaunchHandler(ref, rootMessengerKey);
    _deepLink = DeepLinkHandler(ref);
    _deepLink!.start();
  }

  @override
  void dispose() {
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
    final phase = ref.read(routingPhaseProvider);
    debugPrint('DeepLink consume: phase=${phase.name} pending=${pending?.kind}');
    if (pending == null) return;
    switch (phase) {
      case RoutingPhase.loading:
      case RoutingPhase.error:
      case RoutingPhase.signedOut:
        return; // wait - consumed downstream or after authentication
      case RoutingPhase.needsToPick:
      case RoutingPhase.ready:
        switch (pending.kind) {
          case DeepLinkKind.join:
            debugPrint('DeepLink: pushing ${_joinLocation(pending.code)}');
            ref.read(appRouterProvider).push(_joinLocation(pending.code));
            ref.read(pendingDeepLinkControllerProvider.notifier).clear();
          case DeepLinkKind.claim:
            // Claiming is a fresh sign-up that takes over a managed member, so
            // it can't apply to an account you're already in. The handler owns
            // the pending link from here (kept across a delete-and-claim so the
            // signed-out flow can finish the job).
            _handleSignedInClaim();
          case DeepLinkKind.nfcTap:
            // The handler switches to the tag's household itself (if the
            // tapper's a member), so this works at needsToPick or ready - no
            // pre-selected household required.
            debugPrint(
              'DeepLink: nfc-tap hh=${pending.householdId} '
              'subject=${pending.subjectId}',
            );
            ref.read(pendingDeepLinkControllerProvider.notifier).clear();
            _nfcLaunch?.handleNfcTap(pending.householdId, pending.subjectId);
        }
    }
  }

  /// A signed-in user tapped a claim link. Explain that accounts can't be
  /// merged, then either keep their account (drop the link) or delete-and-
  /// claim: a type-to-confirm delete, after which the app drops to signed-out
  /// and `AuthLandingScreen` opens the sign-up pre-filled with the still-
  /// pending claim code.
  Future<void> _handleSignedInClaim() async {
    if (_handlingClaim) return;
    _handlingClaim = true;
    final notifier = ref.read(pendingDeepLinkControllerProvider.notifier);
    try {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) {
        notifier.clear();
        return;
      }
      final wantsDelete = await showClaimWhileSignedInDialog(ctx);
      if (!wantsDelete || !ctx.mounted) {
        notifier.clear(); // keep their account
        return;
      }
      final confirmed = await confirmByTyping(
        ctx,
        title: 'Delete your account?',
        body:
            'This permanently deletes your account and signs you out, then '
            'opens the claim sign-up. Chores you completed stay with your '
            'household, without your name on them.\n\nThis cannot be undone.',
        actionLabel: 'Delete forever',
      );
      if (!confirmed) {
        notifier.clear(); // backed out - don't let it resurface
        return;
      }
      // Keep the pending claim: deletion drops us to signedOut and
      // AuthLandingScreen consumes it (sign-up, pre-filled).
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } catch (e) {
      notifier.clear();
      rootMessengerKey.currentState?.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text('Could not delete account: $e'),
        ),
      );
    } finally {
      _handlingClaim = false;
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
