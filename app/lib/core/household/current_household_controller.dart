import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_controller.dart';
import '../storage/shared_preferences_provider.dart';
import 'household_membership.dart';
import 'household_memberships_controller.dart';

part 'current_household_controller.g.dart';

const _kPersistedKey = 'current_household_id_v1';

/// Picks the currently-active household for the signed-in user.
///
/// Async — consistent with the rest of the data-fetching controllers. The
/// router's `routingPhase` provider buffers this controller's transient
/// `AsyncLoading` states so deep state churn doesn't bounce the user off
/// the screen they're on.
///
/// Resolution rules:
/// - If a persisted household ID is in the user's current memberships, use it.
/// - If the persisted ID is no longer valid, clear it and fall back.
/// - If there's exactly one membership, auto-select it and persist.
/// - Otherwise (0 memberships, or 2+ with no valid persisted choice) return
///   `null` and let the router send the user to setup or picker.
@Riverpod(keepAlive: true)
class CurrentHouseholdController extends _$CurrentHouseholdController {
  @override
  Future<HouseholdMembership?> build() async {
    // Watch auth synchronously before any await so the controller rebuilds
    // when login state changes.
    final auth = ref.watch(authControllerProvider);
    final memberships =
        await ref.watch(householdMembershipsControllerProvider.future);

    // If the user is signed out, leave the persisted choice alone — it's
    // still relevant when they sign back in. If we cleared it here, the
    // logout-then-login cycle would always lose their last selection.
    if (!auth.isAuthenticated) return null;

    final prefs = ref.read(sharedPreferencesProvider);
    final persistedId = prefs.getString(_kPersistedKey);

    if (persistedId != null) {
      for (final m in memberships) {
        if (m.householdId == persistedId) return m;
      }
      // Signed in, but the persisted choice isn't in this user's
      // memberships any more. Drop it.
      await prefs.remove(_kPersistedKey);
    }

    if (memberships.length == 1) {
      final only = memberships.first;
      await prefs.setString(_kPersistedKey, only.householdId);
      return only;
    }

    return null;
  }

  /// Switches the active household. Must be one of the user's memberships.
  Future<void> setCurrent(String householdId) async {
    final memberships =
        await ref.read(householdMembershipsControllerProvider.future);
    final m = memberships.firstWhere(
      (m) => m.householdId == householdId,
      orElse: () => throw StateError(
        'Tried to switch to household $householdId but the user is not a member.',
      ),
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kPersistedKey, householdId);
    state = AsyncData(m);
  }

  /// Forgets the persisted choice. Useful on logout.
  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kPersistedKey);
    state = const AsyncData(null);
  }
}
