import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/deeplink/pending_deep_link.dart';
import '../../l10n/l10n.dart';
import 'login_form.dart';
import 'signup_form.dart';

/// Entry point for unauthenticated users: big sticker logo over a faint
/// paw-print backdrop, a welcome line, then the login or signup form.
/// The footer link flips between the two. The router redirects here
/// whenever the user is signed out.
class AuthLandingScreen extends ConsumerStatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  ConsumerState<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends ConsumerState<AuthLandingScreen> {
  bool _showLogin = true;

  /// Claim code lifted from a pending claim deep link, handed to [SignupForm].
  String? _claimCode;

  @override
  void initState() {
    super.initState();
    // Cold-start case: the link was captured before this screen mounted, so
    // its value is already sitting in the provider. ref.listen (in build) only
    // catches *later* changes, so read the current value here after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeConsumeClaim());
  }

  /// If a claim link is pending, switch to the Sign-up tab pre-filled with the
  /// code and clear the pending link so tab flips / rebuilds don't re-trigger.
  void _maybeConsumeClaim() {
    if (!mounted) return;
    final pending = ref.read(pendingDeepLinkControllerProvider);
    if (pending == null || pending.kind != DeepLinkKind.claim) return;
    setState(() {
      _showLogin = false;
      _claimCode = pending.code;
    });
    ref.read(pendingDeepLinkControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Warm case: a claim link tapped while this screen is already on top.
    ref.listen(pendingDeepLinkControllerProvider, (_, next) {
      if (next?.kind == DeepLinkKind.claim) _maybeConsumeClaim();
    });

    // Background gradient + paw prints come from the app-wide AppBackdrop.
    return Scaffold(
      body: SafeArea(
        // Sits a touch above true centre when the content is shorter
        // than the screen; scrolls normally when the keyboard
        // squeezes it.
        child: Align(
          alignment: const Alignment(0, -0.4),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/general/logo.png',
                    height: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(height: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showLogin
                        ? context.l10n.authWelcomeBack
                        : context.l10n.authJoinFamily,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showLogin
                        ? context.l10n.authLoginTagline
                        : context.l10n.authSignupTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_showLogin)
                    const LoginForm()
                  else
                    SignupForm(initialClaimCode: _claimCode),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showLogin
                            ? context.l10n.authNoAccount
                            : context.l10n.authHaveAccount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showLogin = !_showLogin),
                        child: Text(
                          _showLogin
                              ? context.l10n.authSignUp
                              : context.l10n.authLogIn,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
