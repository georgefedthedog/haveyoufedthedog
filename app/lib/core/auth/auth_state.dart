import 'package:pocketbase/pocketbase.dart';

/// Snapshot of who is signed in, if anyone.
///
/// Use the factory constructors - never the private constructor directly.
class AuthState {
  final bool isAuthenticated;
  final RecordModel? user;

  const AuthState._(this.isAuthenticated, this.user);

  factory AuthState.signedOut() => const AuthState._(false, null);
  factory AuthState.authenticated(RecordModel user) => AuthState._(true, user);

  String? get userId => user?.id;
  String? get email => user?.data['email'] as String?;
  String? get displayName => user?.data['name'] as String?;

  /// Id of the user's chosen profile avatar (matches `AvatarRegistry`).
  /// Null when the user hasn't picked yet - UI renders the silhouette.
  String? get avatar {
    final v = user?.data['avatar'];
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  /// Per-user push-mute flags (stored muted-polarity so the missing-field
  /// default of `false` means "notifications on" for every existing record).
  bool get muteOverdue => user?.data['mute_overdue'] == true;
  bool get muteCompletions => user?.data['mute_completions'] == true;
  bool get muteAwards => user?.data['mute_awards'] == true;

  // Equality on identity (signed-in-ness + user id), not record contents.
  // Note this does NOT throttle watchers by itself: AsyncNotifier notifies
  // on every data→data emission regardless of equality, and
  // `provider.future` re-notifies on every state assignment. Controllers
  // that only care about identity watch
  // `authControllerProvider.selectAsync((a) => a.userId)` instead - that's
  // what keeps profile-data churn (avatar, name, fcm_token) from
  // refetching the world.
  @override
  bool operator ==(Object other) =>
      other is AuthState &&
      other.isAuthenticated == isAuthenticated &&
      other.user?.id == user?.id;

  @override
  int get hashCode => Object.hash(isAuthenticated, user?.id);
}
