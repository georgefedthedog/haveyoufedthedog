/// Compile-time configuration for the PocketBase backend.
class PbConfig {
  PbConfig._();

  /// Live PocketBase deployment. Override at build time with
  /// `--dart-define=PB_BASE_URL=...` for local dev.
  static const baseUrl = String.fromEnvironment(
    'PB_BASE_URL',
    defaultValue: 'https://api.haveyoufedthedog.com',
  );

  /// flutter_secure_storage key for the persisted auth token blob.
  static const authStorageKey = 'pb_auth_v1';
}
