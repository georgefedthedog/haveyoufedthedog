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

    // Darker than the plain surface, with the house BL→TR lift.
    final bgHsl = HSLColor.fromColor(scheme.surface);
    final bgDark = bgHsl
        .withLightness((bgHsl.lightness - 0.07).clamp(0.0, 1.0))
        .toColor();
    final bgLight = bgHsl
        .withLightness((bgHsl.lightness - 0.02).clamp(0.0, 1.0))
        .toColor();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [bgDark, bgLight],
          ),
        ),
        child: Stack(
          children: [
          const Positioned.fill(
            child: IgnorePointer(child: _PawPrintBackdrop()),
          ),
          SafeArea(
            // Centre vertically when the content is shorter than the
            // screen; scrolls normally when the keyboard squeezes it.
            child: Center(
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
          ],
        ),
      ),
    );
  }
}

/// Faint paw prints scattered around the page edges — pure [Icons.pets]
/// at low opacity, no asset needed.
class _PawPrintBackdrop extends StatelessWidget {
  const _PawPrintBackdrop();

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.06);
    // (alignment x, alignment y, size, rotation in radians)
    const paws = <(double, double, double, double)>[
      (-0.9, -0.9, 64, -0.4),
      (0.95, -0.55, 44, 0.5),
      (-0.88, -0.15, 38, 0.3),
      (0.9, 0.1, 56, -0.35),
      (-0.92, 0.5, 46, 0.45),
      (0.88, 0.78, 70, -0.2),
      (-0.45, 0.95, 40, 0.25),
    ];
    return Stack(
      children: [
        for (final (x, y, size, angle) in paws)
          Align(
            alignment: Alignment(x, y),
            child: Transform.rotate(
              angle: angle,
              child: Icon(Icons.pets, size: size, color: color),
            ),
          ),
      ],
    );
  }
}
