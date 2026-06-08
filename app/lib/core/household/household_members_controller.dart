import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'household_member.dart';

part 'household_members_controller.g.dart';

/// All members of a given household, with their display names resolved.
///
/// Family parameter: the household id. Each instance is cached separately,
/// so opening multiple households' detail screens doesn't refetch the same
/// one twice.
///
/// **State-management notes:** `ref.watch` happens for both providers
/// synchronously before any `await`. The per-user `getOne` calls are wrapped
/// in try/catch so a stale or forbidden user record doesn't drop the whole
/// list.
@Riverpod(keepAlive: true)
class HouseholdMembersController extends _$HouseholdMembersController {
  @override
  Future<List<HouseholdMember>> build(String householdId) async {
    final pb = ref.watch(pocketbaseClientProvider);
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) return const [];

    final memberRecords = await pb
        .collection('household_members')
        .getFullList(filter: 'household = "$householdId"');

    final result = <HouseholdMember>[];
    for (final m in memberRecords) {
      final userId = m.data['user'] as String?;
      if (userId == null) continue;

      String displayName = '(unknown)';
      try {
        final u = await pb.collection('users').getOne(userId);
        final name = u.data['name'] as String?;
        if (name != null && name.isNotEmpty) {
          displayName = name;
        }
      } catch (e) {
        // Most likely a permission-denied — the server hasn't been updated
        // to allow cross-user reads. Falling back to "(unknown)" is fine.
        debugPrint('Could not fetch user $userId: $e');
      }

      result.add(HouseholdMember(
        membershipId: m.id,
        userId: userId,
        displayName: displayName,
        role: m.data['role'] as String? ?? 'member',
      ));
    }
    return result;
  }
}
