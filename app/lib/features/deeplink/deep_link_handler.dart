import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      if (initial != null) {
        _handle(initial);
      } else {
        await _recoverColdLinkFromNative();
      }
    } catch (e) {
      // No initial link, or a platform without support - ignore.
      debugPrint('DeepLink: getInitialLink threw: $e');
    }
  }

  /// iOS fallback: under the implicit-engine embedding, `app_links` misses the
  /// cold-launch universal link, so the native `AppDelegate` stashes it in
  /// shared_preferences (`cold_deep_link`). Poll briefly - the native
  /// `continueUserActivity` callback can land just after this runs. Android is
  /// unaffected (getInitialLink returns the URL there, so this never runs).
  Future<void> _recoverColdLinkFromNative() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    for (var i = 0; i < 10; i++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final native = prefs.getString('cold_deep_link');
        if (native != null && native.isNotEmpty) {
          await prefs.remove('cold_deep_link');
          debugPrint('DeepLink: recovered cold link from native = $native');
          _handle(Uri.parse(native));
          return;
        }
      } catch (e) {
        debugPrint('DeepLink: native fallback read failed: $e');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    debugPrint('DeepLink: no native cold link after poll');
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
      'nfc-tap' => DeepLinkKind.nfcTap,
      _ => null,
    };
    if (kind == null) return;
    // join/claim carry `code`; an nfc-tap carries `subject` (+ optional
    // `household` so a multi-household member logs against the right house
    // without switching first).
    final PendingDeepLink pending;
    if (kind == DeepLinkKind.nfcTap) {
      pending = PendingDeepLink(
        kind: kind,
        subjectId: uri.queryParameters['subject']?.trim() ?? '',
        householdId: uri.queryParameters['household']?.trim() ?? '',
      );
    } else {
      pending = PendingDeepLink(
        kind: kind,
        code: uri.queryParameters['code']?.trim() ?? '',
      );
    }
    debugPrint(
      'DeepLink: parked $kind code=${pending.code} '
      'hh=${pending.householdId} subject=${pending.subjectId} from $uri',
    );
    _ref.read(pendingDeepLinkControllerProvider.notifier).set(pending);
  }
}
