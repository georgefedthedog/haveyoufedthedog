import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import 'current_household_controller.dart';
import 'household_members_controller.dart';
import 'households_controller.dart';

part 'household_actions.g.dart';

/// Side-effect provider exposing imperative household operations.
@Riverpod(keepAlive: true)
HouseholdActions householdActions(Ref ref) => HouseholdActions(ref);

/// **Not** a Riverpod notifier — actions don't have their own state. State
/// lives in `HouseholdsController` / `CurrentHouseholdController`.
class HouseholdActions {
  final Ref _ref;
  HouseholdActions(this._ref);

  Future<String> _currentUserId() async {
    final auth = await _ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (userId == null) {
      throw StateError('Operation requires a signed-in user.');
    }
    return userId;
  }

  /// Creates a household, makes the current user its owner, and switches
  /// to it. The router redirect will send the user to /home as soon as
  /// the household list updates.
  Future<void> createHousehold(String name) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final userId = await _currentUserId();

    final household = await pb.collection('households').create(body: {
      'name': name,
      'created_by': userId,
      'invites_open': false,
    });

    await pb.collection('household_members').create(body: {
      'household': household.id,
      'user': userId,
      'role': 'owner',
    });

    _ref.invalidate(householdsControllerProvider);
    await _ref
        .read(currentHouseholdControllerProvider.notifier)
        .setCurrent(household.id);
  }

  /// Joins an existing household via an invite code. Calls the custom
  /// server endpoint `/api/custom/join-household-by-code` which enforces
  /// that the household has `invites_open = true` and the code matches.
  Future<void> joinByCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();

    final response = await pb.send<Map<String, dynamic>>(
      '/api/custom/join-household-by-code',
      method: 'POST',
      body: {'code': code},
    );

    final householdId = response['householdId'] as String?;
    if (householdId == null) {
      throw Exception('Server returned an unexpected response.');
    }

    _ref.invalidate(householdsControllerProvider);
    await _ref
        .read(currentHouseholdControllerProvider.notifier)
        .setCurrent(householdId);
  }

  Future<void> renameHousehold({
    required String householdId,
    required String newName,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('households').update(householdId, body: {
      'name': newName,
    });
    // Surgical update — no full refetch, so the router doesn't bounce the
    // user to the splash screen mid-edit.
    _ref
        .read(householdsControllerProvider.notifier)
        .updateOneInPlace(householdId: householdId, name: newName);
  }

  Future<void> leaveHousehold({required String membershipId}) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('household_members').delete(membershipId);
    _ref.invalidate(householdsControllerProvider);
  }

  Future<void> deleteHousehold({required String householdId}) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('households').delete(householdId);
    _ref.invalidate(householdsControllerProvider);
  }

  Future<void> kickMember({
    required String membershipId,
    required String householdId,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('household_members').delete(membershipId);
    _ref.invalidate(householdMembersControllerProvider(householdId));
  }

  /// Opens or closes the invite door on a household.
  ///
  /// When opening: generates a fresh code and stores it.
  /// When closing: clears the code so any cached copies are useless even
  /// if `invites_open` is flipped back on (which will mint a new code).
  Future<void> setInvitesOpen({
    required String householdId,
    required bool open,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final code = open ? _generateInviteCode() : null;
    await pb.collection('households').update(householdId, body: {
      'invites_open': open,
      'invite_code': code ?? '',
    });
    _ref
        .read(householdsControllerProvider.notifier)
        .updateOneInPlace(
          householdId: householdId,
          inviteCode: code,
          invitesOpen: open,
          clearInviteCode: !open,
        );
  }

  /// Rotates the invite code for a household that already has invites open.
  /// Old code is immediately invalidated.
  Future<void> rotateInviteCode(String householdId) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final code = _generateInviteCode();
    await pb.collection('households').update(householdId, body: {
      'invite_code': code,
    });
    _ref
        .read(householdsControllerProvider.notifier)
        .updateOneInPlace(householdId: householdId, inviteCode: code);
  }
}

/// Charset excludes visually-ambiguous characters (0/O, 1/I/L) so codes
/// shared verbally or in screenshots are unambiguous.
const _inviteAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
final _inviteRand = Random.secure();

String _generateInviteCode() {
  String chunk() => List.generate(
        4,
        (_) => _inviteAlphabet[_inviteRand.nextInt(_inviteAlphabet.length)],
      ).join();
  return '${chunk()}-${chunk()}';
}
