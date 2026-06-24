import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import '../catalog/catalog_controller.dart';
import 'current_household_controller.dart';
import 'household_members_controller.dart';
import 'households_controller.dart';

part 'household_actions.g.dart';

/// Side-effect provider exposing imperative household operations.
@Riverpod(keepAlive: true)
HouseholdActions householdActions(Ref ref) => HouseholdActions(ref);

/// **Not** a Riverpod notifier - actions don't have their own state. State
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
  Future<void> createHousehold(String name, {String residents = ''}) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final userId = await _currentUserId();

    // The creator's phone defines the household's wall clock - the
    // overdue cron schedules pushes against this. Best-effort: an
    // unresolvable zone leaves the field empty and the server assumes
    // Europe/London.
    String timezone = '';
    try {
      timezone = await FlutterTimezone.getLocalTimezone();
    } catch (_) {}

    final household = await pb
        .collection('households')
        .create(
          body: {
            'name': name,
            'created_by': userId,
            'invites_open': false,
            'timezone': timezone,
            'residents': residents,
          },
        );

    await pb
        .collection('household_members')
        .create(
          body: {'household': household.id, 'user': userId, 'role': 'owner'},
        );

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

  /// Redeems an image-pack code for [householdId] via the custom server
  /// endpoint (the pack code field is hidden from clients, so only the
  /// hook can resolve it). Idempotent server-side. On success, patches
  /// the cached household's pack list in place (so the picker gate updates)
  /// and invalidates the remote catalog so it refetches the now-relevant
  /// pack's art - otherwise the in-memory catalog still predates it and the
  /// art wouldn't appear until the next sign-in (which is the only other
  /// thing that refetches the catalog).
  ///
  /// Returns the pack's display name for the confirmation snackbar.
  Future<({String name, bool alreadyApplied})> redeemPackCode({
    required String householdId,
    required String rawCode,
  }) async {
    final code = rawCode.trim().toUpperCase();
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();

    final response = await pb.send<Map<String, dynamic>>(
      '/api/custom/redeem-pack-code',
      method: 'POST',
      body: {'code': code, 'householdId': householdId},
    );

    final packId = response['packId'] as String?;
    final name = response['name'] as String?;
    if (packId == null || name == null) {
      throw Exception('Server returned an unexpected response.');
    }
    final alreadyApplied = response['alreadyApplied'] == true;

    if (!alreadyApplied) {
      final current = _ref
          .read(householdsControllerProvider)
          .valueOrNull
          ?.where((h) => h.id == householdId)
          .firstOrNull;
      _ref
          .read(householdsControllerProvider.notifier)
          .updateOneInPlace(
            householdId: householdId,
            packs: [...?current?.packIds, packId],
          );
      _ref.invalidate(remoteCatalogProvider);
    }
    return (name: name, alreadyApplied: alreadyApplied);
  }

  /// Claims a free streak-unlock of a catalog [kind] (`character` or
  /// `picture`) by [slug] for [householdId]. Calls
  /// `/api/custom/claim-streak-reward`, which recomputes the household's
  /// reward streak server-side and only grants when it clears the threshold -
  /// so a client can't forge an unlock. On a fresh grant, patches the cached
  /// household's unlocked-slug list in place so the picker gate lights up
  /// immediately (the art already resolves via the live catalog, so unlike
  /// pack redemption there's no catalog refetch to do).
  ///
  /// Throws [ClientException] (with the server message) when the streak is too
  /// short or the item isn't available - the caller surfaces it.
  Future<({String slug, bool alreadyUnlocked})> claimStreakReward({
    required String householdId,
    required String kind,
    required String slug,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();

    final response = await pb.send<Map<String, dynamic>>(
      '/api/custom/claim-streak-reward',
      method: 'POST',
      body: {'householdId': householdId, 'kind': kind, 'slug': slug},
    );

    final grantedSlug = response['slug'] as String? ?? slug;
    final alreadyUnlocked = response['alreadyUnlocked'] == true;

    if (!alreadyUnlocked) {
      final current = _ref
          .read(householdsControllerProvider)
          .valueOrNull
          ?.where((h) => h.id == householdId)
          .firstOrNull;
      final isCharacter = kind == 'character';
      final existing = isCharacter
          ? current?.unlockedCharacterIds
          : current?.unlockedPictureIds;
      final next = [...?existing, grantedSlug];
      _ref
          .read(householdsControllerProvider.notifier)
          .updateOneInPlace(
            householdId: householdId,
            unlockedCharacters: isCharacter ? next : null,
            unlockedPictures: isCharacter ? null : next,
            // The hook re-anchors server-side; mirror it so the local reward
            // streak re-zeros immediately (counter restarts for the next one).
            lastFreeRedemption: DateTime.now(),
          );
    }
    return (slug: grantedSlug, alreadyUnlocked: alreadyUnlocked);
  }

  /// Verifies a completed store purchase server-side and applies the packs it
  /// grants to [householdId]. Calls `/api/custom/verify-purchase`, which
  /// validates the receipt with the store (Play / App Store), records the
  /// transaction, and appends the product's granted packs to the household's
  /// `packs` relation. Idempotent server-side: a Restore re-verifies the same
  /// transaction and returns `alreadyApplied`.
  ///
  /// On a fresh grant, patches the cached household's pack list in place (so
  /// the picker gate updates) and invalidates the remote catalog so it
  /// refetches the granted packs' art, so it appears in the pickers without a
  /// sign-out/in (same as [redeemPackCode]).
  ///
  /// Returns the product name + the granted pack ids for the confirmation.
  Future<({String name, List<String> packIds, bool alreadyApplied})>
  verifyAndApplyPurchase({
    required String householdId,
    required String platform,
    required String sku,
    required String purchaseToken,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();

    final response = await pb.send<Map<String, dynamic>>(
      '/api/custom/verify-purchase',
      method: 'POST',
      body: {
        'platform': platform,
        'sku': sku,
        'purchaseToken': purchaseToken,
        'householdId': householdId,
      },
    );

    final name = response['name'] as String?;
    final packIdsRaw = response['packIds'] as List?;
    if (name == null || packIdsRaw == null) {
      throw Exception('Server returned an unexpected response.');
    }
    final packIds = [for (final p in packIdsRaw) p.toString()];
    final alreadyApplied = response['alreadyApplied'] == true;

    if (!alreadyApplied) {
      final current = _ref
          .read(householdsControllerProvider)
          .valueOrNull
          ?.where((h) => h.id == householdId)
          .firstOrNull;
      final merged = <String>{...?current?.packIds, ...packIds}.toList();
      _ref
          .read(householdsControllerProvider.notifier)
          .updateOneInPlace(householdId: householdId, packs: merged);
      _ref.invalidate(remoteCatalogProvider);
    }
    return (name: name, packIds: packIds, alreadyApplied: alreadyApplied);
  }

  /// Updates one or more user-editable fields on a household in a single
  /// PB call. Pass `null` for fields you don't want to touch; pass an
  /// empty string to clear a string field. Patches the cached household
  /// in place after the round-trip so home / details rebuild without a
  /// full invalidation (which would bounce the router to splash).
  Future<void> updateHousehold({
    required String householdId,
    String? name,
    String? picture,
    String? residents,
    String? timezone,
  }) async {
    if (name == null &&
        picture == null &&
        residents == null &&
        timezone == null) {
      return;
    }
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (picture != null) body['picture'] = picture;
    if (residents != null) body['residents'] = residents;
    if (timezone != null) body['timezone'] = timezone;
    await pb.collection('households').update(householdId, body: body);
    _ref
        .read(householdsControllerProvider.notifier)
        .updateOneInPlace(
          householdId: householdId,
          name: name,
          picture: picture,
          residents: residents,
          timezone: timezone,
        );
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

  /// Creates a "managed" member in [householdId] - a loginless
  /// `users` row that earns credit and awards, logged for via "Act as". The
  /// owner-only `/api/custom/managed-member` hook mints the user + joins it
  /// to the household (an owner can't do either directly under the collection
  /// rules). Refetches the members list so the new chip appears.
  Future<void> createManagedMember({
    required String householdId,
    required String name,
    String? avatar,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();
    await pb.send<Map<String, dynamic>>(
      '/api/custom/managed-member',
      method: 'POST',
      body: {'householdId': householdId, 'name': name.trim(), 'avatar': avatar ?? ''},
    );
    _ref.invalidate(householdMembersControllerProvider(householdId));
  }

  /// Edits a managed member's name and/or avatar via the hook (owners can't
  /// update a `users` row they can't log in as). [userId] is the managed
  /// user's id (`HouseholdMember.userId`). Pass `null` to leave a field
  /// untouched; an empty avatar string clears it.
  Future<void> updateManagedMember({
    required String householdId,
    required String userId,
    String? name,
    String? avatar,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (avatar != null) body['avatar'] = avatar;
    if (body.isEmpty) return;
    await pb.send<Map<String, dynamic>>(
      '/api/custom/managed-member/$userId',
      method: 'PATCH',
      body: body,
    );
    _ref.invalidate(householdMembersControllerProvider(householdId));
  }

  /// Deletes a managed member entirely (the loginless `users` row). Their
  /// membership cascades; past completions keep counting but render as
  /// "Someone" (the `completed_by` relation is cascadeDelete:false).
  Future<void> deleteManagedMember({
    required String householdId,
    required String userId,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();
    await pb.send<Map<String, dynamic>>(
      '/api/custom/managed-member/$userId',
      method: 'DELETE',
    );
    _ref.invalidate(householdMembersControllerProvider(householdId));
  }

  /// Opens or closes "claiming" on a managed member - the way the person takes
  /// over the loginless account on Sign Up. Mirrors [setInvitesOpen]: opening
  /// generates a fresh code (same `XXXX-YYYY` format as a household invite) and
  /// stores it via the owner-only hook; closing clears it. The current code is
  /// read off the members view (`HouseholdMember.claimCode`), so we invalidate
  /// the list to refresh it. Returns the new code when opening, null on close.
  Future<String?> setClaimOpen({
    required String userId,
    required String householdId,
    required bool open,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await _currentUserId();
    final code = open ? _generateInviteCode() : '';
    await pb.send<Map<String, dynamic>>(
      '/api/custom/managed-member/$userId/claim-code',
      method: 'POST',
      body: {'code': code},
    );
    _ref.invalidate(householdMembersControllerProvider(householdId));
    return open ? code : null;
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
    await pb
        .collection('households')
        .update(
          householdId,
          body: {'invites_open': open, 'invite_code': code ?? ''},
        );
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
    await pb
        .collection('households')
        .update(householdId, body: {'invite_code': code});
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
