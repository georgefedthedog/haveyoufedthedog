import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_controller.dart';
import 'current_household_controller.dart';
import 'household_member.dart';
import 'household_members_controller.dart';

part 'acting_user_controller.g.dart';

/// Who the device is currently logging chores *as* - the "Act as" identity.
///
/// Holds a `users` id. Defaults to the signed-in user (you log as yourself),
/// but an owner/helper can switch to any member of the current household so a
/// phone-less member can mark their own chores on a borrowed phone. Whatever
/// id this holds is what [completionActions] stamps onto `completed_by`.
///
/// **Sticky for the session, never persisted.** `build` watches the active
/// household id and the signed-in user id (identity-scoped, so a rename or
/// avatar change doesn't disturb it); when either changes - a household
/// switch, a logout - the notifier rebuilds and resets to self. A cold start
/// therefore always begins as yourself. The visible banner + red-ringed You
/// icon are the cue that you're still acting as someone else within a session.
@Riverpod(keepAlive: true)
class ActingUserController extends _$ActingUserController {
  @override
  Future<String?> build() async {
    // Identity-scoped watches - see HouseholdsController for why not `.future`.
    final myUserId = await ref.watch(
      authControllerProvider.selectAsync((a) => a.userId),
    );
    // Establish the dependency so switching household resets to self; the id
    // itself isn't needed here.
    await ref.watch(
      currentHouseholdControllerProvider.selectAsync((h) => h?.id),
    );
    return myUserId; // default: act as yourself
  }

  /// Switch to acting as [userId]. Restricted to **managed (phone-less)**
  /// members of the current household: a real member has their own phone, so
  /// logging as them would only let someone game their standing. Real members
  /// keep self-only attribution.
  Future<void> setActing(String userId) async {
    final household = await ref.read(currentHouseholdControllerProvider.future);
    if (household == null) {
      throw StateError('No active household to act within.');
    }
    final members = await ref.read(
      householdMembersControllerProvider(household.id).future,
    );
    HouseholdMember? target;
    for (final m in members) {
      if (m.userId == userId) {
        target = m;
        break;
      }
    }
    if (target == null || !target.isManaged) {
      throw StateError('You can only act as a phone-less member.');
    }
    state = AsyncData(userId);
  }

  /// Back to logging as the signed-in user.
  Future<void> revertToSelf() async {
    final auth = await ref.read(authControllerProvider.future);
    state = AsyncData(auth.userId);
  }
}

/// The household member the device is currently acting as - resolves the
/// acting user id against the current household's member list. Used to show
/// the right name/avatar on celebrations, the "Acting as" banner, and the
/// red-ringed You icon. Null when signed out, no active household, or the
/// acting user isn't among the current household's members.
@riverpod
Future<HouseholdMember?> actingMember(Ref ref) async {
  final actingId = await ref.watch(actingUserControllerProvider.future);
  if (actingId == null) return null;
  final household = await ref.watch(currentHouseholdControllerProvider.future);
  if (household == null) return null;
  final members = await ref.watch(
    householdMembersControllerProvider(household.id).future,
  );
  for (final m in members) {
    if (m.userId == actingId) return m;
  }
  return null;
}
