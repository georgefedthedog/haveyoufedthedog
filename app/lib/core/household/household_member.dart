import 'package:pocketbase/pocketbase.dart';

/// One member of a household, as seen from the inside. Wraps a row from the
/// `household_member_details` PB View — a server-side JOIN of
/// `household_members` and `users` that exposes only the safe fields
/// (id, household, user, role, user_name, user_avatar).
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
  /// Null when the user hasn't picked yet — UI renders the silhouette.
  String? get avatar {
    final v = record.data['user_avatar'];
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  bool get isOwner => role == 'owner';
}
