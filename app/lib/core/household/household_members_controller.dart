import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'household_member.dart';

part 'household_members_controller.g.dart';

/// All members of a given household, with their display names resolved.
///
/// Reads from the `household_member_details` PB View. Family parameter:
/// the household id.
@Riverpod(keepAlive: true)
class HouseholdMembersController extends _$HouseholdMembersController {
  @override
  Future<List<HouseholdMember>> build(String householdId) async {
    final pbFuture = ref.watch(pocketbaseClientProvider.future);
    // Identity-scoped watch - see HouseholdsController for why not `.future`.
    final userIdFuture = ref.watch(
      authControllerProvider.selectAsync((a) => a.userId),
    );

    final pb = await pbFuture;
    final userId = await userIdFuture;
    if (userId == null) return const [];

    try {
      // Oldest membership first - owner (creator) leads, then joiners in
      // the order they arrived.
      final records = await pb
          .collection('household_member_details')
          .getFullList(filter: 'household = "$householdId"', sort: 'created');
      return records.map(HouseholdMember.new).toList();
    } catch (e) {
      debugPrint('household_member_details fetch failed: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
