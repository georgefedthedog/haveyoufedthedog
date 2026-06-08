import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/auth_controller.dart';
import '../core/household/current_household_controller.dart';
import '../core/household/household_memberships_controller.dart';
import '../features/auth/auth_landing_screen.dart';
import '../features/home/home_screen.dart';
import '../features/household/create_household_screen.dart';
import '../features/household/household_details_screen.dart';
import '../features/household/household_picker_screen.dart';
import '../features/household/household_setup_screen.dart';
import '../features/household/join_household_screen.dart';
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
        path: Routes.householdCreate,
        builder: (context, state) => const CreateHouseholdScreen(),
      ),
      GoRoute(
        path: Routes.householdJoin,
        builder: (context, state) => const JoinHouseholdScreen(),
      ),
      GoRoute(
        path: Routes.householdDetailsPattern,
        builder: (context, state) => HouseholdDetailsScreen(
          householdId: state.pathParameters['id']!,
        ),
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
String? _redirect(Ref ref, String loc) {
  // 1. Not signed in.
  final auth = ref.read(authControllerProvider);
  if (!auth.isAuthenticated) {
    return loc == Routes.auth ? null : Routes.auth;
  }

  // 2. Memberships not loaded yet (or errored — show splash).
  final memberships = ref.read(householdMembershipsControllerProvider);
  if (memberships.isLoading || memberships.hasError) {
    return loc == Routes.splash ? null : Routes.splash;
  }
  final list = memberships.requireValue;

  // 3. Zero memberships → forced to setup.
  if (list.isEmpty) {
    return loc == Routes.householdSetup ? null : Routes.householdSetup;
  }

  // 4. Current household not yet resolved.
  final current = ref.read(currentHouseholdControllerProvider);
  if (current.isLoading) {
    return loc == Routes.splash ? null : Routes.splash;
  }
  final currentValue = current.valueOrNull;

  // 5. 2+ memberships with no valid persisted choice → forced to picker.
  if (currentValue == null) {
    return loc == Routes.householdPicker ? null : Routes.householdPicker;
  }

  // 6. Fully set up. Bounce off "forced" gate screens, but NOT off the
  //    picker, create, or join — those are also reachable voluntarily from
  //    the home screen.
  const forcedGates = {
    Routes.splash,
    Routes.auth,
    Routes.householdSetup,
  };
  if (forcedGates.contains(loc)) return Routes.home;
  return null;
}
