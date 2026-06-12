import 'package:flutter/material.dart';

import 'login_form.dart';
import 'signup_form.dart';

/// Entry point for unauthenticated users: big sticker logo over a faint
/// paw-print backdrop, a welcome line, then the login or signup form.
/// The footer link flips between the two. The router redirects here
/// whenever the user is signed out.
class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                    _showLogin ? 'Welcome back!' : 'Join the family',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showLogin
                        ? 'Log in to keep your pup happy and well-fed.'
                        : 'Sign up and never wonder who fed '
                              'the dog again.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_showLogin) const LoginForm() else const SignupForm(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showLogin
                            ? "Don't have an account?"
                            : 'Already have an account?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showLogin = !_showLogin),
                        child: Text(_showLogin ? 'Sign up' : 'Log in'),
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
