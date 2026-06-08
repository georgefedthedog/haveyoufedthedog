/// One member of a household, as seen from the inside (name + role).
/// Joined from a `household_members` record + the related `users` record.
class HouseholdMember {
  /// Primary key of the `household_members` row.
  final String membershipId;

  /// Primary key of the `users` row.
  final String userId;

  /// Display name. Falls back to "(unknown)" if the user record couldn't be
  /// fetched (e.g. permission denied because the server schema wasn't
  /// updated to allow cross-user reads).
  final String displayName;

  /// `owner` or `member` — server-side enum.
  final String role;

  const HouseholdMember({
    required this.membershipId,
    required this.userId,
    required this.displayName,
    required this.role,
  });

  bool get isOwner => role == 'owner';
}
