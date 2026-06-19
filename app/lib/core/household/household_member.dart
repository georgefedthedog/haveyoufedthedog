import 'package:pocketbase/pocketbase.dart';

/// One member of a household, as seen from the inside. Wraps a row from the
/// `household_member_details` PB View - a server-side JOIN of
/// `household_members` and `users` that exposes only the safe fields
/// (id, household, user, role, user_name, user_avatar, user_managed).
class HouseholdMember {
  final RecordModel record;
  const HouseholdMember(this.record);

  /// Primary key of the `household_members` row.
  String get membershipId => record.id;

  String get householdId => record.data['household'] as String;

  /// Primary key of the `users` row.
  String get userId => record.data['user'] as String;

  /// `owner` or `member`.
  String get role => record.data['role'] as String? ?? 'member';

  /// Display name. Falls back to "(unknown)" if the View couldn't surface it.
  String get displayName =>
      (record.data['user_name'] as String?) ?? '(unknown)';

  /// Id of the user's chosen profile avatar (matches `AvatarRegistry`).
  /// Null when the user hasn't picked yet - UI renders the silhouette.
  String? get avatar {
    final v = record.data['user_avatar'];
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  bool get isOwner => role == 'owner';

  /// A "managed" member: a loginless `users` row the owner
  /// created, logged for via "Act as". The View surfaces `users.managed`;
  /// SQLite bools can come back as bool/int/string, so accept all forms.
  bool get isManaged {
    final v = record.data['user_managed'];
    return v == true || v == 1 || v == '1';
  }

  /// The current claim code (from `users.claim_code` via the view) - the person
  /// enters this on Sign Up to take over the managed account. Empty when
  /// claiming is closed. Members-scoped on the view, like the household invite
  /// code.
  String get claimCode {
    final v = record.data['user_claim_code'];
    return (v is String) ? v : '';
  }

  /// Claiming is currently open for this managed member.
  bool get canBeClaimed => isManaged && claimCode.isNotEmpty;
}
