import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'household_membership.dart';

part 'household_memberships_controller.g.dart';

/// Loads the current user's household memberships from PocketBase. Rebuilds
/// when auth state changes (login / logout / signup).
///
/// Returns an empty list if the user is signed out.
///
/// **State-management notes:**
/// - Both `ref.watch` calls happen *before* any `await`, so Riverpod's
///   dependency tracking stays intact.
/// - We deliberately do two PB calls (memberships → each household) rather
///   than `expand: 'household'`. The expand API in the PB Dart SDK 0.22 has
///   sharp edges (lists vs singletons) we'd rather avoid.
@Riverpod(keepAlive: true)
class HouseholdMembershipsController extends _$HouseholdMembershipsController {
  @override
  Future<List<HouseholdMembership>> build() async {
    final pb = ref.watch(pocketbaseClientProvider);
    final auth = ref.watch(authControllerProvider);

    if (!auth.isAuthenticated || auth.userId == null) return const [];
    final userId = auth.userId!;

    final memberRecords = await pb
        .collection('household_members')
        .getFullList(filter: 'user = "$userId"');

    final result = <HouseholdMembership>[];

    for (final m in memberRecords) {
      final hhId = m.data['household'] as String?;

      if (hhId == null || hhId.isEmpty) continue;

      try {
        final h = await pb.collection('households').getOne(hhId);

        result.add(
          HouseholdMembership(
            membershipId: m.id,
            householdId: hhId,
            householdName: h.data['name'] as String? ?? 'Unnamed household',
            role: m.data['role'] as String? ?? 'member',
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
}
