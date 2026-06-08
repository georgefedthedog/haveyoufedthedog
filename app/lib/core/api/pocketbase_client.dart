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
/// Self-contained — no `main()` override dance. Downstream providers
/// `await ref.watch(pocketbaseClientProvider.future)` once and the SDK
/// caches the resolved client for the rest of the session.
@Riverpod(keepAlive: true)
Future<PocketBase> pocketbaseClient(Ref ref) async {
  final initial = await _secureStorage.read(key: _kPbAuthKey);
  return PocketBase(
    _pbBaseUrl,
    authStore: AsyncAuthStore(
      initial: initial,
      save: (data) => _secureStorage.write(key: _kPbAuthKey, value: data),
      clear: () => _secureStorage.delete(key: _kPbAuthKey),
    ),
  );
}
