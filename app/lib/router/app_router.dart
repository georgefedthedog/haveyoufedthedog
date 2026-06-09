import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app/root_nav_shell.dart';
import '../features/auth/auth_landing_screen.dart';
import '../features/chores/edit_chore_screen.dart';
import '../features/history/history_tab_screen.dart';
import '../features/home/home_screen.dart';
import '../features/household/create_household_screen.dart';
import '../features/household/household_details_screen.dart';
import '../features/household/household_picker_screen.dart';
import '../features/household/invite_screen.dart';
import '../features/household/join_household_screen.dart';
import '../features/onboarding/onboarding_welcome_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/you_tab_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/subjects/edit_subject_screen.dart';
import '../features/subjects/subject_detail_screen.dart';
import '../features/subjects/subjects_tab_screen.dart';
import 'router_refresh_notifier.dart';
import 'routing_phase.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// The app router. Built once; reacts to routing-phase changes only.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      // Full-screen routes (no bottom nav shell).
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.auth,
        builder: (context, state) => const AuthLandingScreen(),
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
        path: Routes.householdInvitePattern,
        builder: (context, state) => InviteScreen(
          householdId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: Routes.subjectNew,
        builder: (context, state) => const EditSubjectScreen(),
      ),
      GoRoute(
        path: Routes.subjectEditPattern,
        builder: (context, state) => EditSubjectScreen(
          subjectId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: Routes.subjectDetailPattern,
        builder: (context, state) => SubjectDetailScreen(
          subjectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: Routes.choreNewPattern,
        builder: (context, state) => EditChoreScreen(
          subjectId: state.pathParameters['subjectId'],
        ),
      ),
      GoRoute(
        path: Routes.choreEditPattern,
        builder: (context, state) => EditChoreScreen(
          choreId: state.pathParameters['id'],
        ),
      ),
      // Bottom-nav shell — four tab branches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RootNavShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.subjectsTab,
              builder: (context, state) => const SubjectsTabScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.historyTab,
              builder: (context, state) => HistoryTabScreen(
                initialSubjectFilter:
                    state.uri.queryParameters['subject'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.youTab,
              builder: (context, state) => const YouTabScreen(),
            ),
          ]),
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

    case RoutingPhase.signedOut:
      return loc == Routes.auth ? null : Routes.auth;

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
      const forcedGates = {
        Routes.splash,
        Routes.auth,
      };
      if (forcedGates.contains(loc)) return Routes.home;
      return null;
  }
}
