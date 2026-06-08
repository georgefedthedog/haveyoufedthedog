import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_controller.dart';
import '../storage/shared_preferences_provider.dart';
import 'household.dart';
import 'households_controller.dart';

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
/// - If a persisted household ID is in the user's current list, use it.
/// - If the persisted ID is no longer valid, clear it and fall back.
/// - If there's exactly one household, auto-select it and persist.
/// - Otherwise (0 households, or 2+ with no valid persisted choice) return
///   `null` and let the router send the user to setup or picker.
@Riverpod(keepAlive: true)
class CurrentHouseholdController extends _$CurrentHouseholdController {
  @override
  Future<Household?> build() async {
    final authFuture = ref.watch(authControllerProvider.future);
    final householdsFuture = ref.watch(householdsControllerProvider.future);
    final prefsFuture = ref.watch(sharedPreferencesProvider.future);

    final auth = await authFuture;
    final households = await householdsFuture;
    final prefs = await prefsFuture;

    // If the user is signed out, leave the persisted choice alone — it's
    // still relevant when they sign back in. If we cleared it here, the
    // logout-then-login cycle would always lose their last selection.
    if (!auth.isAuthenticated) return null;

    final persistedId = prefs.getString(_kPersistedKey);

    if (persistedId != null) {
      for (final h in households) {
        if (h.id == persistedId) return h;
      }
      // Signed in, but the persisted choice isn't in this user's list any
      // more. Drop it.
      await prefs.remove(_kPersistedKey);
    }

    if (households.length == 1) {
      final only = households.first;
      await prefs.setString(_kPersistedKey, only.id);
      return only;
    }

    return null;
  }

  /// Switches the active household. Must be one of the user's households.
  Future<void> setCurrent(String householdId) async {
    final households =
        await ref.read(householdsControllerProvider.future);
    final h = households.firstWhere(
      (h) => h.id == householdId,
      orElse: () => throw StateError(
        'Tried to switch to household $householdId but the user is not a member.',
      ),
    );
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kPersistedKey, householdId);
    state = AsyncData(h);
  }

  /// Forgets the persisted choice. Useful on logout.
  Future<void> clear() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_kPersistedKey);
    state = const AsyncData(null);
  }
}
