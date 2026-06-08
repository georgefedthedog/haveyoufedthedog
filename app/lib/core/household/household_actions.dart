import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'current_household_controller.dart';
import 'household_members_controller.dart';
import 'household_memberships_controller.dart';

part 'household_actions.g.dart';

/// Side-effect provider exposing imperative household operations: create a
/// new household, or join one by invite code. After a successful action we
/// invalidate the memberships and current-household controllers so the
/// router redirects the user to the right place.
@Riverpod(keepAlive: true)
HouseholdActions householdActions(Ref ref) => HouseholdActions(ref);

/// **Not** a Riverpod notifier — actions don't have their own state. State
/// lives in `HouseholdMembershipsController` / `CurrentHouseholdController`.
class HouseholdActions {
  final Ref _ref;
  HouseholdActions(this._ref);

  /// Creates a household, makes the current user its owner, and switches
  /// to it. The router redirect will send the user to /home as soon as
  /// the memberships list updates.
  Future<void> createHousehold(String name) async {
    final pb = _ref.read(pocketbaseClientProvider);
    final auth = _ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null) {
      throw StateError('Cannot create a household when signed out.');
    }

    final household = await pb.collection('households').create(body: {
      'name': name,
      'created_by': userId,
    });

    await pb.collection('household_members').create(body: {
      'household': household.id,
      'user': userId,
      'role': 'owner',
    });

    // Refetch memberships, then set this household as the current one.
    _ref.invalidate(householdMembershipsControllerProvider);
    await _ref.read(currentHouseholdControllerProvider.notifier)
        .setCurrent(household.id);
  }

  /// Joins an existing household via an invite code. Throws if the code
  /// is unknown or expired.
  Future<void> joinByCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final pb = _ref.read(pocketbaseClientProvider);
    final auth = _ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null) {
      throw StateError('Cannot join a household when signed out.');
    }

    final invites = await pb.collection('household_invites').getList(
          page: 1,
          perPage: 1,
          filter: 'code = "$code"',
        );
    if (invites.items.isEmpty) {
      throw Exception('That invite code doesn\'t exist.');
    }
    final invite = invites.items.first;

    final expiresAt = invite.data['expires_at'] as String?;
    if (expiresAt != null && expiresAt.isNotEmpty) {
      final exp = DateTime.tryParse(expiresAt);
      if (exp != null && exp.isBefore(DateTime.now().toUtc())) {
        throw Exception('That invite code has expired.');
      }
    }

    final householdId = invite.data['household'] as String;

    // Don't double-add if already a member.
    final existing = await pb.collection('household_members').getList(
          page: 1,
          perPage: 1,
          filter: 'user = "$userId" && household = "$householdId"',
        );
    if (existing.items.isEmpty) {
      await pb.collection('household_members').create(body: {
        'household': householdId,
        'user': userId,
        'role': 'member',
      });
    }

    _ref.invalidate(householdMembershipsControllerProvider);
    await _ref.read(currentHouseholdControllerProvider.notifier)
        .setCurrent(householdId);
  }

  /// Renames a household. Only owners should call this — the server's
  /// `updateRule` enforces auth but not role, so we gate in the UI.
  Future<void> renameHousehold({
    required String householdId,
    required String newName,
  }) async {
    final pb = _ref.read(pocketbaseClientProvider);
    await pb.collection('households').update(householdId, body: {
      'name': newName,
    });
    _ref.invalidate(householdMembershipsControllerProvider);
  }

  /// Removes the current user from a household by deleting their membership
  /// row. If this was the current household, `CurrentHouseholdController`
  /// will detect the stale persisted ID on next rebuild and fall back.
  Future<void> leaveHousehold({required String membershipId}) async {
    final pb = _ref.read(pocketbaseClientProvider);
    await pb.collection('household_members').delete(membershipId);
    _ref.invalidate(householdMembershipsControllerProvider);
  }

  /// Permanently deletes a household. PB cascade-deletes the membership
  /// rows, subjects, chores, and completions belonging to it. Owners only.
  Future<void> deleteHousehold({required String householdId}) async {
    final pb = _ref.read(pocketbaseClientProvider);
    await pb.collection('households').delete(householdId);
    _ref.invalidate(householdMembershipsControllerProvider);
  }

  /// Removes another member from a household. The UI enforces that only
  /// owners can do this and that they can't kick themselves.
  Future<void> kickMember({
    required String membershipId,
    required String householdId,
  }) async {
    final pb = _ref.read(pocketbaseClientProvider);
    await pb.collection('household_members').delete(membershipId);
    _ref.invalidate(householdMembersControllerProvider(householdId));
  }
}
