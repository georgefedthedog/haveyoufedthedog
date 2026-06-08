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
}
