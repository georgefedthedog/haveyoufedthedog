import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'household.dart';

part 'households_controller.g.dart';

/// Loads the current user's households from PocketBase. Each one wraps a
/// `households` record and carries the user's role + membershipId from
/// the related `household_members` row. Rebuilds when auth changes.
///
/// Returns an empty list if the user is signed out.
///
/// **State-management notes:**
/// - All `ref.watch` calls happen *before* any `await`, so Riverpod's
///   dependency tracking stays intact across the async boundary.
/// - We deliberately do two PB calls (memberships → each household) rather
///   than `expand: 'household'`. The expand API in the PB Dart SDK 0.22 has
///   sharp edges (lists vs singletons) we'd rather avoid.
@Riverpod(keepAlive: true)
class HouseholdsController extends _$HouseholdsController {
  @override
  Future<List<Household>> build() async {
    final pbFuture = ref.watch(pocketbaseClientProvider.future);
    // Select the user id rather than watching `.future`: auth re-emits on
    // every profile-data write (avatar, name, fcm_token), and `.future`
    // re-notifies unconditionally - this list only changes when the *user*
    // changes.
    final userIdFuture = ref.watch(
      authControllerProvider.selectAsync((a) => a.userId),
    );

    final pb = await pbFuture;
    final userId = await userIdFuture;

    if (userId == null) return const [];

    final memberRecords = await pb
        .collection('household_members')
        .getFullList(filter: 'user = "$userId"');

    final result = <Household>[];

    for (final m in memberRecords) {
      final hhId = m.data['household'] as String?;
      if (hhId == null || hhId.isEmpty) continue;

      try {
        final h = await pb.collection('households').getOne(hhId);
        result.add(
          Household(
            record: h,
            role: m.data['role'] as String? ?? 'member',
            membershipId: m.id,
          ),
        );
      } catch (e) {
        // Likely a stale membership pointing at a deleted household, or a
        // perm issue. Skip rather than crash the whole list.
        debugPrint('Could not fetch household $hhId: $e');
      }
    }
    return result;
  }

  Future<void> refresh() async => ref.invalidateSelf();

  /// Updates one household in place without going through `AsyncLoading`.
  /// Used for actions that change a household's fields (rename, invite
  /// settings) - these don't change the LIST, so the router doesn't bump
  /// the user to splash and back.
  ///
  /// Mutates the underlying RecordModel's `data` map directly. Safe here
  /// because no other code holds a reference to these records, and we
  /// emit a fresh list to trigger watchers.
  void updateOneInPlace({
    required String householdId,
    String? name,
    String? inviteCode,
    bool? invitesOpen,
    bool clearInviteCode = false,
    String? picture,
    String? residents,
    String? timezone,
    List<String>? packs,
  }) {
    final current = state.valueOrNull;
    if (current == null) return;

    for (final h in current) {
      if (h.id != householdId) continue;
      if (name != null) h.record.data['name'] = name;
      if (clearInviteCode) {
        h.record.data['invite_code'] = '';
      } else if (inviteCode != null) {
        h.record.data['invite_code'] = inviteCode;
      }
      if (invitesOpen != null) h.record.data['invites_open'] = invitesOpen;
      if (picture != null) h.record.data['picture'] = picture;
      if (residents != null) h.record.data['residents'] = residents;
      if (timezone != null) h.record.data['timezone'] = timezone;
      if (packs != null) h.record.data['packs'] = packs;
      break;
    }
    state = AsyncData([...current]);
  }
}
