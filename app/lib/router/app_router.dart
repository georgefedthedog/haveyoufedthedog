import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app/root_nav_shell.dart';
import '../features/auth/auth_landing_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/chores/edit_chore_screen.dart';
import '../features/completions/celebration_args.dart';
import '../features/completions/completion_celebration.dart';
import '../features/completions/day_celebration.dart';
import '../features/history/history_tab_screen.dart';
import '../features/home/home_screen.dart';
import '../features/household/create_household_screen.dart';
import '../features/household/household_details_screen.dart';
import '../features/household/household_picker_screen.dart';
import '../features/household/join_household_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/you_tab_screen.dart';
import '../features/rewards/rewards_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/splash/startup_error_screen.dart';
import '../features/store/store_screen.dart';
import '../features/subjects/edit_subject_screen.dart';
import '../features/subjects/subject_detail_screen.dart';
import '../features/subjects/subjects_tab_screen.dart';
import '../widgets/app_backdrop.dart';
import 'router_refresh_notifier.dart';
import 'routing_phase.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Root navigator key. Lets code outside the widget tree (e.g. AppRoot's
/// deep-link handling) show dialogs over whatever's currently on screen via
/// `rootNavigatorKey.currentContext`.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Wraps a routed page in its own [AppBackdrop] so the gradient travels with
/// the page. The global backdrop in `MaterialApp.builder` sits behind the
/// whole Navigator, which is invisible once a page lands - but during iOS's
/// horizontal slide the incoming scaffold is transparent, so you see the page
/// underneath bleed through. Giving each full-screen page its own opaque
/// backdrop closes that gap. The transparent celebration overlays (opaque:
/// false) are deliberately left unwrapped so the page below still shows.
Widget _backdrop(Widget child) => AppBackdrop(child: child);

/// The app router. Built once; reacts to routing-phase changes only.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      // Full-screen routes (no bottom nav shell).
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => _backdrop(const SplashScreen()),
      ),
      GoRoute(
        path: Routes.startupError,
        builder: (context, state) => _backdrop(const StartupErrorScreen()),
      ),
      GoRoute(
        path: Routes.auth,
        builder: (context, state) => _backdrop(const AuthLandingScreen()),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => _backdrop(
          ForgotPasswordScreen(initialEmail: state.extra as String?),
        ),
      ),
      GoRoute(
        path: Routes.householdPicker,
        builder: (context, state) => _backdrop(const HouseholdPickerScreen()),
      ),
      GoRoute(
        path: Routes.householdCreate,
        builder: (context, state) => _backdrop(const CreateHouseholdScreen()),
      ),
      GoRoute(
        path: Routes.householdJoin,
        builder: (context, state) => _backdrop(
          JoinHouseholdScreen(initialCode: state.uri.queryParameters['code']),
        ),
      ),
      GoRoute(
        path: Routes.householdDetailsPattern,
        builder: (context, state) => _backdrop(
          HouseholdDetailsScreen(householdId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => _backdrop(const EditProfileScreen()),
      ),
      GoRoute(
        path: Routes.store,
        builder: (context, state) => _backdrop(const StoreScreen()),
      ),
      GoRoute(
        path: Routes.rewards,
        builder: (context, state) => _backdrop(const RewardsScreen()),
      ),
      GoRoute(
        path: Routes.celebration,
        pageBuilder: (context, state) {
          final args = state.extra as CelebrationArgs;
          return CustomTransitionPage<void>(
            opaque: false,
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            child: CompletionCelebration(args: args),
          );
        },
      ),
      GoRoute(
        path: Routes.dayCelebration,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          opaque: false,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          child: const DayCelebration(),
        ),
      ),
      GoRoute(
        path: Routes.subjectNew,
        builder: (context, state) => _backdrop(const EditSubjectScreen()),
      ),
      GoRoute(
        path: Routes.subjectEditPattern,
        builder: (context, state) =>
            _backdrop(EditSubjectScreen(subjectId: state.pathParameters['id'])),
      ),
      GoRoute(
        path: Routes.subjectDetailPattern,
        builder: (context, state) => _backdrop(
          SubjectDetailScreen(subjectId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: Routes.choreNewPattern,
        builder: (context, state) => _backdrop(
          EditChoreScreen(subjectId: state.pathParameters['subjectId']),
        ),
      ),
      GoRoute(
        path: Routes.choreEditPattern,
        builder: (context, state) =>
            _backdrop(EditChoreScreen(choreId: state.pathParameters['id'])),
      ),
      // Bottom-nav shell - four tab branches in a swipeable PageView.
      // The custom container form (not .indexedStack) hands every branch
      // Navigator to RootNavShell so it can host them as pages.
      StatefulShellRoute(
        builder: (context, state, shell) => _backdrop(shell),
        navigatorContainerBuilder: (context, shell, children) =>
            RootNavShell(shell: shell, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => HomeScreen(
                  initialSubjectFilter: state.uri.queryParameters['subject'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.subjectsTab,
                builder: (context, state) => const SubjectsTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.historyTab,
                builder: (context, state) => const HistoryTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.youTab,
                builder: (context, state) => const YouTabScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// One switch over [RoutingPhase]. The phase is the only thing the router
/// reads, so any state churn that doesn't change the phase (e.g. an invite
/// code rotation) leaves the redirect alone.
String? _redirect(Ref ref, String loc) {
  switch (ref.read(routingPhaseProvider)) {
    case RoutingPhase.loading:
      return loc == Routes.splash ? null : Routes.splash;

    case RoutingPhase.error:
      return loc == Routes.startupError ? null : Routes.startupError;

    case RoutingPhase.signedOut:
      const allowedSignedOut = {Routes.auth, Routes.forgotPassword};
      return allowedSignedOut.contains(loc) ? null : Routes.auth;

    case RoutingPhase.needsToPick:
      // Allow `/household-create`, `/household-join` and `/profile` even
      // in this phase. Create/Join wire the picker's primary buttons;
      // profile is the escape hatch (log out) for users stuck with zero
      // households.
      const allowedInPickerPhase = {
        Routes.householdPicker,
        Routes.householdCreate,
        Routes.householdJoin,
        Routes.profile,
      };
      if (allowedInPickerPhase.contains(loc)) return null;
      return Routes.householdPicker;

    case RoutingPhase.ready:
      // Bounce off the forced gates if the user somehow lands on them
      // while already set up.
      const forcedGates = {Routes.splash, Routes.auth};
      if (forcedGates.contains(loc)) return Routes.home;
      return null;
  }
}
