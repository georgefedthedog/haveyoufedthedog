import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'household_member.dart';

part 'household_members_controller.g.dart';

/// All members of a given household, with their display names resolved.
///
/// Reads from the `household_member_details` PB View — a server-side JOIN
/// of `household_members` and `users` that exposes only the safe fields
/// (id, household, user, role, user_name). This avoids weakening the
/// `users` collection's security rules.
///
/// Family parameter: the household id.
///
/// **State-management notes:** `ref.watch` happens for both providers
/// synchronously before any `await`. If the View isn't deployed yet the
/// fetch will error and the screen shows it via `AsyncValue.error`.
@Riverpod(keepAlive: true)
class HouseholdMembersController extends _$HouseholdMembersController {
  @override
  Future<List<HouseholdMember>> build(String householdId) async {
    final pb = ref.watch(pocketbaseClientProvider);
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) return const [];

    try {
      final records = await pb
          .collection('household_member_details')
          .getFullList(filter: 'household = "$householdId"');

      return records
          .map((r) => HouseholdMember(
                membershipId: r.id,
                userId: r.data['user'] as String? ?? '',
                displayName:
                    (r.data['user_name'] as String?) ?? '(unknown)',
                role: r.data['role'] as String? ?? 'member',
              ))
          .toList();
    } catch (e) {
      debugPrint('household_member_details fetch failed: $e');
      rethrow;
    }
  }
}
