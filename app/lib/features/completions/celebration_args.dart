import '../../core/subjects/character.dart';

/// Typed payload passed to the `/celebration` GoRoute via `state.extra`.
///
/// Kept in its own file so both the route registration (in `app_router.dart`)
/// and the call sites can import it without dragging the celebration widget
/// itself along.
///
/// [streak] is the **post-completion** streak count for the subject. Pass 0
/// (or any value < 1) to hide the streak pill on the overlay.
class CelebrationArgs {
  final Character character;
  final String choreName;
  final String? whoName;

  /// Avatar id of the user who completed the chore (matches `AvatarRegistry`).
  /// Null when the logger hasn't picked an avatar — overlay renders the
  /// silhouette next to their name.
  final String? whoAvatar;
  final int streak;

  const CelebrationArgs({
    required this.character,
    required this.choreName,
    this.whoName,
    this.whoAvatar,
    this.streak = 0,
  });
}
