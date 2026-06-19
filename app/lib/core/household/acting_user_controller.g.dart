// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acting_user_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$actingMemberHash() => r'654ffd9f76a20f753e104c21f4203e0886b20b3d';

/// The household member the device is currently acting as - resolves the
/// acting user id against the current household's member list. Used to show
/// the right name/avatar on celebrations, the "Acting as" banner, and the
/// red-ringed You icon. Null when signed out, no active household, or the
/// acting user isn't among the current household's members.
///
/// Copied from [actingMember].
@ProviderFor(actingMember)
final actingMemberProvider =
    AutoDisposeFutureProvider<HouseholdMember?>.internal(
      actingMember,
      name: r'actingMemberProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$actingMemberHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActingMemberRef = AutoDisposeFutureProviderRef<HouseholdMember?>;
String _$actingUserControllerHash() =>
    r'463b46a6f153f2e4171ebe3a971602ca0469683f';

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
///
/// Copied from [ActingUserController].
@ProviderFor(ActingUserController)
final actingUserControllerProvider =
    AsyncNotifierProvider<ActingUserController, String?>.internal(
      ActingUserController.new,
      name: r'actingUserControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$actingUserControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActingUserController = AsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
