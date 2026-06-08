import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Watch auth state so the router rebuilds (and re-evaluates redirects)
  // whenever the user logs in or out. Step 4 will extract this into a
  // dedicated `auth_guard.dart` with finer-grained refresh handling.
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: auth.isAuthenticated ? Routes.home : Routes.login,
    redirect: (context, state) {
      final goingToLogin = state.matchedLocation == Routes.login;
      if (!auth.isAuthenticated && !goingToLogin) return Routes.login;
      if (auth.isAuthenticated && goingToLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}
