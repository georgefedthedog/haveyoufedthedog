/// A household, as seen by a member of it. Flat by design: we only ever
/// fetch households in the context of "the current user is a member," so
/// the user's role and membership row PK are part of the entity rather than
/// living in a separate wrapper.
///
/// Distinct from [HouseholdMember], which represents a *peer* user's row
/// when viewing a single household's members list.
class Household {
  /// Primary key in the `households` collection.
  final String id;

  /// Display name, e.g. "Paihia House".
  final String name;

  /// The current user's role in this household — `owner` or `member`.
  final String role;

  /// Primary key of the `household_members` row that grants the current
  /// user access. Needed for leave / kick operations.
  final String membershipId;

  /// Current rotating invite code, or null when invites are closed.
  /// Only meaningful when [invitesOpen] is true.
  final String? inviteCode;

  /// Whether new members can join right now.
  final bool invitesOpen;

  const Household({
    required this.id,
    required this.name,
    required this.role,
    required this.membershipId,
    required this.inviteCode,
    required this.invitesOpen,
  });

  bool get isOwner => role == 'owner';
}
