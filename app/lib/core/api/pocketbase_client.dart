import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pocketbase_client.g.dart';

/// The app-wide PocketBase client. We do the async initial-token load in
/// `main()` and override this provider with the resulting instance, so
/// everything downstream gets a synchronous `PocketBase`.
///
/// See `main.dart` for the override.
@Riverpod(keepAlive: true)
PocketBase pocketbaseClient(Ref ref) {
  throw UnimplementedError(
    'pocketbaseClientProvider must be overridden in main() — '
    'the client needs an async auth-token load before the app starts.',
  );
}
