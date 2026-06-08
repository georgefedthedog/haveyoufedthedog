import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_root.dart';
import 'core/api/pb_config.dart';
import 'core/api/pocketbase_client.dart';
import 'core/storage/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final initial = await storage.read(key: PbConfig.authStorageKey);

  final pb = PocketBase(
    PbConfig.baseUrl,
    authStore: AsyncAuthStore(
      initial: initial,
      save: (data) async =>
          storage.write(key: PbConfig.authStorageKey, value: data),
      clear: () async => storage.delete(key: PbConfig.authStorageKey),
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        pocketbaseClientProvider.overrideWithValue(pb),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AppRoot(),
    ),
  );
}
