import 'dart:async';

import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import 'auth_state.dart';

part 'auth_controller.g.dart';

/// Tracks PocketBase auth state and exposes login / signup / logout.
///
/// `AsyncNotifier` because the PocketBase client is itself async — we wait
/// for it to load on first build, then watch `authStore.onChange` to push
/// further updates.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  StreamSubscription<AuthStoreEvent>? _sub;

  @override
  Future<AuthState> build() async {
    final pb = await ref.watch(pocketbaseClientProvider.future);

    _sub?.cancel();
    _sub = pb.authStore.onChange.listen((_) {
      state = AsyncData(_snapshot(pb));
    });
    ref.onDispose(() => _sub?.cancel());

    return _snapshot(pb);
  }

  AuthState _snapshot(PocketBase pb) {
    if (!pb.authStore.isValid) return AuthState.signedOut();
    final record = pb.authStore.record;
    if (record == null) return AuthState.signedOut();
    return AuthState.authenticated(record);
  }

  Future<void> login({required String email, required String password}) async {
    final pb = await ref.read(pocketbaseClientProvider.future);
    await pb.collection('users').authWithPassword(email, password);
    // The authStore.onChange listener installed in build() updates state.
  }

  Future<void> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final pb = await ref.read(pocketbaseClientProvider.future);
    await pb.collection('users').create(
      body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': displayName,
      },
    );
    // PB doesn't sign you in on create — log in immediately so the rest of
    // the app sees you as authenticated.
    await pb.collection('users').authWithPassword(email, password);
  }

  Future<void> logout() async {
    final pb = await ref.read(pocketbaseClientProvider.future);
    pb.authStore.clear();
  }

  /// Updates editable profile fields on the signed-in user.
  ///
  /// Doesn't trigger an `AuthState` rebuild — [AuthState] compares on
  /// `(isAuthenticated, userId)` only, so name/avatar changes don't
  /// invalidate downstream watchers. Screens reading `auth.displayName`
  /// see the new value on their next read because the underlying
  /// `authStore.record` data was mutated in place.
  Future<void> updateProfile({String? name}) async {
    final pb = await ref.read(pocketbaseClientProvider.future);
    final auth = await ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (userId == null) {
      throw StateError('Cannot update profile when signed out.');
    }
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (body.isEmpty) return;
    await pb.collection('users').update(userId, body: body);
  }
}
