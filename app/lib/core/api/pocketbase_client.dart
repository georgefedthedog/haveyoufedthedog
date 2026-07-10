import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pocketbase_client.g.dart';

const _pbBaseUrl = String.fromEnvironment(
  'PB_BASE_URL',
  defaultValue: 'https://api.haveyoufedthedog.com',
);

const _kPbAuthKey = 'pb_auth_v1';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Async-initialised PocketBase client. Reads any persisted auth token
/// from secure storage so the user stays signed in across launches.
///
/// Self-contained - no `main()` override dance. Downstream providers
/// `await ref.watch(pocketbaseClientProvider.future)` once and the SDK
/// caches the resolved client for the rest of the session.
@Riverpod(keepAlive: true)
Future<PocketBase> pocketbaseClient(Ref ref) async {
  final initial = await _readPersistedAuth();
  return PocketBase(
    _pbBaseUrl,
    authStore: AsyncAuthStore(
      initial: initial,
      save: (data) => _secureStorage.write(key: _kPbAuthKey, value: data),
      clear: () => _secureStorage.delete(key: _kPbAuthKey),
    ),
  );
}

/// Reads the persisted auth token, tolerating an unreadable secure store.
///
/// The encrypted store can become undecryptable when its ciphertext survives
/// but the AES key that wrote it is gone - e.g. the app is restored onto a
/// new phone (or reinstalled across a signing-key change) via Android backup,
/// since the Keystore key is device-bound and never travels. `read` then
/// throws (`AEADBadTagException`) instead of returning; left unhandled that
/// error bubbles up through auth and hangs the app on the splash forever.
///
/// Recover by wiping the whole store and starting signed-out - the user just
/// logs in again. Use `deleteAll`, not `delete`: the corruption is the
/// androidx keyset shared across the store, so clearing our one key leaves it
/// broken and the next launch fails identically.
Future<String?> _readPersistedAuth() async {
  try {
    return await _secureStorage.read(key: _kPbAuthKey);
  } catch (e, st) {
    debugPrint('Secure storage read failed, resetting store: $e\n$st');
    try {
      await _secureStorage.deleteAll();
    } catch (e2) {
      debugPrint('Secure storage deleteAll (post read failure) failed: $e2');
    }
    return null;
  }
}
