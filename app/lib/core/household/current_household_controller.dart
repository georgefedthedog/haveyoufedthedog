import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/shared_preferences_provider.dart';
import 'household_membership.dart';
import 'household_memberships_controller.dart';

part 'current_household_controller.g.dart';

const _kPersistedKey = 'current_household_id_v1';

/// Picks the currently-active household for the signed-in user.
///
/// Resolution rules:
/// - If a persisted household ID is in the user's current membership list,
///   that one wins.
/// - If the persisted ID is no longer valid (e.g. household deleted, user
///   removed) we clear it and fall back to the other rules.
/// - If there is exactly one membership, auto-select it and persist.
/// - Otherwise (0 memberships, or 2+ with no valid persisted choice) we
///   return `null` so the router can send the user to setup or the picker.
///
/// **State-management notes:** the only `ref.watch` is `householdMemberships
/// ControllerProvider.future`, called synchronously before any other `await`,
/// so dependency tracking stays clean. `setCurrent` and `clear` use
/// `ref.read` because they're imperative methods, not part of `build()`.
@Riverpod(keepAlive: true)
class CurrentHouseholdController extends _$CurrentHouseholdController {
  @override
  Future<HouseholdMembership?> build() async {
    final memberships = await ref.watch(
      householdMembershipsControllerProvider.future,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    final persistedId = prefs.getString(_kPersistedKey);

    if (persistedId != null) {
      for (final m in memberships) {
        if (m.householdId == persistedId) return m;
      }
      // Persisted choice no longer valid — drop it.
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
    final memberships = await ref.read(
      householdMembershipsControllerProvider.future,
    );

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
