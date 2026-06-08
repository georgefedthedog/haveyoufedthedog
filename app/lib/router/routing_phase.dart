import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/auth_controller.dart';
import '../core/household/current_household_controller.dart';
import '../core/household/households_controller.dart';

part 'routing_phase.g.dart';

/// The single signal the router cares about.
///
/// Whatever state changes downstream — household renames, invite codes
/// rotated, chores added or deleted — the *routing decision* only depends
/// on these five buckets. By isolating them in their own enum we can wrap
/// the router's `refreshListenable` around just this provider; deep state
/// changes (e.g. an invite_code rotating) won't re-fire the redirect,
/// because the resulting `RoutingPhase` value is unchanged and Riverpod
/// skips notifying listeners when a provider's value is equal to its
/// previous one.
enum RoutingPhase {
  /// Auth / households still loading on app start. Show splash.
  loading,

  /// No valid session. Show login / signup.
  signedOut,

  /// Authenticated, but no household is currently selected. Either the
  /// user has zero households (empty state with Create/Join), or 2+ and
  /// none persisted. The picker handles both cases.
  needsToPick,

  /// Fully resolved — the user has a current household. Show app routes.
  ready,
}

/// Derives the current [RoutingPhase] from auth + households + current.
///
/// Returns an enum value, so the router's listener only fires on actual
/// phase transitions. Adding a chore, renaming a household, etc. won't
/// produce a different phase — so the router doesn't bounce the user.
@Riverpod(keepAlive: true)
RoutingPhase routingPhase(Ref ref) {
  final authAsync = ref.watch(authControllerProvider);
  final auth = authAsync.valueOrNull;
  if (auth == null) return RoutingPhase.loading;
  if (!auth.isAuthenticated) return RoutingPhase.signedOut;

  final households = ref.watch(householdsControllerProvider);
  if (households.isLoading || households.hasError) {
    return RoutingPhase.loading;
  }
  final list = households.requireValue;
  if (list.isEmpty) return RoutingPhase.needsToPick;

  final currentAsync = ref.watch(currentHouseholdControllerProvider);
  // Treat as loading while a rebuild is in flight AND the previous value
  // was null (or we have no value yet). This covers:
  //   - fresh app start (no value yet)
  //   - the login transition (previous value was null from signed-out state,
  //     now resolving against the freshly-loaded households)
  //
  // Once we have a non-null household, subsequent `AsyncLoading`
  // transitions (e.g. churn from invalidations) keep the previous value,
  // so this guard doesn't fire — the phase stays `ready` and the user
  // isn't bounced off whatever screen they're on.
  if (currentAsync.isLoading && currentAsync.valueOrNull == null) {
    return RoutingPhase.loading;
  }
  if (currentAsync.hasError) return RoutingPhase.loading;
  if (currentAsync.valueOrNull == null) return RoutingPhase.needsToPick;

  return RoutingPhase.ready;
}
