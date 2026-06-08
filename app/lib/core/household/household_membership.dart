/// A user's membership in a household, joined with the household's display
/// details. Built from a `household_members` record + the related `households`
/// record so the UI doesn't have to do further lookups.
class HouseholdMembership {
  /// Primary key of the underlying `household_members` row.
  final String membershipId;

  /// Primary key of the related `households` row.
  final String householdId;

  /// Display name of the household, e.g. "Paihia House".
  final String householdName;

  /// `owner` or `member` — server-side enum.
  final String role;

  /// Current rotating invite code, or null when invites are closed.
  /// Only meaningful when [invitesOpen] is true.
  final String? inviteCode;

  /// Whether new members can join right now.
  final bool invitesOpen;

  const HouseholdMembership({
    required this.membershipId,
    required this.householdId,
    required this.householdName,
    required this.role,
    required this.inviteCode,
    required this.invitesOpen,
  });

  bool get isOwner => role == 'owner';
}
