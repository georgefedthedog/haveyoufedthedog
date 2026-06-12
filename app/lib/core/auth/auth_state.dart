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

  // Equality on identity, not record contents. Without this, every
  // `authStore.onChange` event produces a fresh AuthState instance and
  // anything watching auth (e.g. fcm_token_sync) rebuilds - including for
  // changes that came from the watcher's own writes, which causes an
  // infinite loop. Profile-data changes (display name, fcm_token) don't
  // affect routing or sync triggers, so we ignore them here.
  @override
  bool operator ==(Object other) =>
      other is AuthState &&
      other.isAuthenticated == isAuthenticated &&
      other.user?.id == user?.id;

  @override
  int get hashCode => Object.hash(isAuthenticated, user?.id);
}
