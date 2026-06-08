import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import 'auth_state.dart';

part 'auth_controller.g.dart';

/// Tracks the current PB auth state and exposes login / signup / logout.
///
/// `build()` is synchronous on purpose — the PB client itself is bootstrapped
/// in `main()` so there is no async work to await here. That keeps Riverpod's
/// dependency tracking simple and avoids the build-cancellation bugs we hit
/// before.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    final pb = ref.watch(pocketbaseClientProvider);
    final sub = pb.authStore.onChange.listen((_) {
      state = _snapshot(pb);
    });
    ref.onDispose(sub.cancel);
    return _snapshot(pb);
  }

  AuthState _snapshot(PocketBase pb) {
    if (!pb.authStore.isValid) return AuthState.signedOut();
    final record = pb.authStore.record;
    if (record == null) return AuthState.signedOut();
    return AuthState.authenticated(record);
  }

  Future<void> login({required String email, required String password}) async {
    final pb = ref.read(pocketbaseClientProvider);
    await pb.collection('users').authWithPassword(email, password);
    // The authStore.onChange listener installed in build() updates state.
  }

  Future<void> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final pb = ref.read(pocketbaseClientProvider);
    await pb
        .collection('users')
        .create(
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
    final pb = ref.read(pocketbaseClientProvider);
    pb.authStore.clear();
  }
}
