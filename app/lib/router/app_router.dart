import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/auth_controller.dart';
import '../core/household/current_household_controller.dart';
import '../core/household/household_memberships_controller.dart';
import '../features/auth/auth_landing_screen.dart';
import '../features/home/home_screen.dart';
import '../features/household/household_picker_screen.dart';
import '../features/household/household_setup_screen.dart';
import '../features/splash/splash_screen.dart';
import 'router_refresh_notifier.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// The app router. Built once; reacts to auth + household state changes via
/// `refreshListenable` (so the router instance itself doesn't get torn down).
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.auth,
        builder: (context, state) => const AuthLandingScreen(),
      ),
      GoRoute(
        path: Routes.householdSetup,
        builder: (context, state) => const HouseholdSetupScreen(),
      ),
      GoRoute(
        path: Routes.householdPicker,
        builder: (context, state) => const HouseholdPickerScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}

/// Redirect logic. Reads the current state of the relevant providers and
/// returns the route the user should be at, or `null` if they're already
/// at the right place.
///
/// Step 4 in the plan calls for extracting this into a dedicated
/// `auth_guard.dart`. For now the rules are simple enough to keep inline.
String? _redirect(Ref ref, String loc) {
  // 1. Not signed in.
  final auth = ref.read(authControllerProvider);
  if (!auth.isAuthenticated) {
    return loc == Routes.auth ? null : Routes.auth;
  }

  // 2. Memberships not loaded yet (or errored — show splash; we'll wire a
  //    real error route later if needed).
  final memberships = ref.read(householdMembershipsControllerProvider);
  if (memberships.isLoading || memberships.hasError) {
    return loc == Routes.splash ? null : Routes.splash;
  }
  final list = memberships.requireValue;

  // 3. Zero memberships → setup.
  if (list.isEmpty) {
    return loc == Routes.householdSetup ? null : Routes.householdSetup;
  }

  // 4. Current household not yet resolved (auto-select runs as a side effect
  //    on initial load when there's exactly one).
  final current = ref.read(currentHouseholdControllerProvider);
  if (current.isLoading) {
    return loc == Routes.splash ? null : Routes.splash;
  }
  final currentValue = current.valueOrNull;

  if (currentValue == null) {
    // We have 2+ memberships and no valid persisted choice → picker.
    return loc == Routes.householdPicker ? null : Routes.householdPicker;
  }

  // 5. All set. Keep them out of the gate screens.
  const gates = {
    Routes.splash,
    Routes.auth,
    Routes.householdSetup,
    Routes.householdPicker,
  };
  if (gates.contains(loc)) return Routes.home;
  return null;
}
