import 'package:pocketbase/pocketbase.dart';

/// Snapshot of who is signed in, if anyone.
///
/// Use the factory constructors — never the private constructor directly.
class AuthState {
  final bool isAuthenticated;
  final RecordModel? user;

  const AuthState._(this.isAuthenticated, this.user);

  factory AuthState.signedOut() => const AuthState._(false, null);
  factory AuthState.authenticated(RecordModel user) =>
      AuthState._(true, user);

  String? get userId => user?.id;
  String? get email => user?.data['email'] as String?;
  String? get displayName => user?.data['name'] as String?;
}
