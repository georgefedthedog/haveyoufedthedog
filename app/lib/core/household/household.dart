import 'package:pocketbase/pocketbase.dart';

/// A household, as seen by a member of it. Wraps the `households` record
/// and carries the user's [role] + [membershipId] from the related
/// `household_members` row - because we only ever look at households in
/// the context of the current user being a member.
///
/// Distinct from [HouseholdMember], which represents a *peer* user's row
/// when viewing a single household's members list.
class Household {
  /// The underlying `households` record.
  final RecordModel record;

  /// The current user's role in this household - `owner` or `member`.
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

  /// IANA timezone of the home ("Europe/London"). Captured from the
  /// creator's phone; the server treats empty as Europe/London.
  String? get timezone {
    final v = record.data['timezone'];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  /// "Who lives here?" - a free-text label like "The Goodchilds".
  String? get residents {
    final v = record.data['residents'];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  bool get invitesOpen => (record.data['invites_open'] as bool?) ?? false;

  /// Ids of the image packs this household has redeemed (`catalog_packs`
  /// relation). Empty for households on the general catalog only.
  ///
  /// Tolerates both PB serializations: multi relations arrive as a list,
  /// but a mis-configured single relation (max select 1) arrives as a
  /// bare string - better to surface that one pack than silently none.
  List<String> get packIds {
    final v = record.data['packs'];
    if (v is List) return [for (final id in v) id.toString()];
    if (v is String && v.isNotEmpty) return [v];
    return const [];
  }

  /// Slugs of catalog characters this household has unlocked for free via a
  /// reward streak (the `claim-streak-reward` hook appends them). These are
  /// OR'd into the character picker's selectable set alongside pack-granted
  /// art. Tolerates list or bare-string serialization like [packIds].
  List<String> get unlockedCharacterIds => _slugList('unlocked_characters');

  /// Slugs of catalog pictures ("houses") unlocked the same way as
  /// [unlockedCharacterIds].
  List<String> get unlockedPictureIds => _slugList('unlocked_pictures');

  List<String> _slugList(String key) {
    final v = record.data[key];
    if (v is List) return [for (final s in v) s.toString()];
    if (v is String && v.isNotEmpty) return [v];
    return const [];
  }

  /// When this household last spent a streak on a free unlock. The reward
  /// counter only counts due-days *after* this anchor, so each claim costs a
  /// fresh run. Null = never claimed.
  DateTime? get lastFreeRedemption {
    final v = record.data['last_free_redemption'];
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  /// Consecutive due-days needed to earn a free unlock. Admin-set per
  /// household; empty/0 means use the default of [_defaultRewardThreshold].
  int get rewardStreakThreshold {
    final v = record.data['reward_streak_threshold'];
    final n = (v is num) ? v.toInt() : 0;
    return n > 0 ? n : _defaultRewardThreshold;
  }

  static const _defaultRewardThreshold = 28;

  bool get isOwner => role == 'owner';
}
