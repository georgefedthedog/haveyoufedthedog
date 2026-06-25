import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/deeplink/pending_deep_link.dart';

/// Receives App Link / Universal Link taps
/// (`https://haveyoufedthedog.com/join` and `/claim`) and parks them in
/// [PendingDeepLinkController]. It does **not** decide where to navigate -
/// that depends on the routing phase (signed in vs out), which `AppRoot` owns.
/// Keeping this a thin parser avoids racing the cold-start auth resolution:
/// on a link-launched cold start the phase is still `loading`, so the link is
/// simply stashed and `AppRoot` acts on it once the phase settles.
///
/// Started once from `AppRoot` and lives for the app's lifetime. Mirrors
/// [NfcLaunchHandler]'s lifecycle.
class DeepLinkHandler {
  final WidgetRef _ref;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  DeepLinkHandler(this._ref);

  Future<void> start() async {
    // Warm path: links arriving while the app is already running.
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (_) {
        /* malformed link - ignore */
      },
    );
    // Cold path: the link that launched the app (null if not launched by one).
    try {
      final initial = await _appLinks.getInitialLink();
      debugPrint('DeepLink: getInitialLink = ${initial ?? "null"}');
      if (initial != null) _handle(initial);
    } catch (e) {
      // No initial link, or a platform without support - ignore.
      debugPrint('DeepLink: getInitialLink threw: $e');
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _handle(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return;
    final kind = switch (segments.first) {
      'join' => DeepLinkKind.join,
      'claim' => DeepLinkKind.claim,
      _ => null,
    };
    if (kind == null) return;
    final code = uri.queryParameters['code']?.trim() ?? '';
    debugPrint('DeepLink: parked $kind code=$code from $uri');
    _ref
        .read(pendingDeepLinkControllerProvider.notifier)
        .set(PendingDeepLink(kind: kind, code: code));
  }
}
