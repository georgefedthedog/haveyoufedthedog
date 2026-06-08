import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/auth_controller.dart';
import '../core/household/current_household_controller.dart';
import '../core/household/household_memberships_controller.dart';

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
  /// Auth / memberships still loading on app start. Show splash.
  loading,

  /// No valid session. Show login / signup.
  signedOut,

  /// Authenticated but the user has zero memberships. Force setup.
  needsHousehold,

  /// Authenticated, 2+ memberships, no current chosen. Force picker.
  needsToPick,

  /// Fully resolved — the user has a current household. Show app routes.
  ready,
}

/// Derives the current [RoutingPhase] from auth + memberships + current.
///
/// Returns an enum value, so the router's listener only fires on actual
/// phase transitions. Adding a chore, renaming a household, etc. won't
/// produce a different phase — so the router doesn't bounce the user.
@Riverpod(keepAlive: true)
RoutingPhase routingPhase(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) return RoutingPhase.signedOut;

  final memberships = ref.watch(householdMembershipsControllerProvider);
  if (memberships.isLoading || memberships.hasError) {
    return RoutingPhase.loading;
  }
  final list = memberships.requireValue;
  if (list.isEmpty) return RoutingPhase.needsHousehold;

  final currentAsync = ref.watch(currentHouseholdControllerProvider);
  // `hasValue` is true on the *first* successful resolution and stays true
  // afterwards (Riverpod preserves the previous value through subsequent
  // `AsyncLoading` transitions). So this only treats the genuine initial
  // load as "loading"; reloads triggered by membership churn use the
  // previous value and keep the phase stable.
  if (!currentAsync.hasValue) return RoutingPhase.loading;
  if (currentAsync.valueOrNull == null) return RoutingPhase.needsToPick;

  return RoutingPhase.ready;
}
