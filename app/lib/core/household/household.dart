import 'package:pocketbase/pocketbase.dart';

/// A household, as seen by a member of it. Wraps the `households` record
/// and carries the user's [role] + [membershipId] from the related
/// `household_members` row — because we only ever look at households in
/// the context of the current user being a member.
///
/// Distinct from [HouseholdMember], which represents a *peer* user's row
/// when viewing a single household's members list.
class Household {
  /// The underlying `households` record.
  final RecordModel record;

  /// The current user's role in this household — `owner` or `member`.
  final String role;

  /// Primary key of the `household_members` row that grants the current
  /// user access. Needed for leave / kick operations.
  final String membershipId;

  const Household({
    required this.record,
    required this.role,
    required this.membershipId,
  });

  String get id => record.id;
  String get name => record.data['name'] as String? ?? 'Unnamed household';

  /// Id of the chosen household picture (see [Picture] / [PictureRegistry]).
  /// Null = unset; clients render the fallback.
  String? get picture {
    final v = record.data['picture'];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  String? get inviteCode {
    final v = record.data['invite_code'];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  bool get invitesOpen => (record.data['invites_open'] as bool?) ?? false;

  bool get isOwner => role == 'owner';
}
