import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/completion_actions.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/nfc/nfc_service.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject_actions.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../completions/celebration_args.dart';

const _channel = MethodChannel('com.haveyoufedthedog/nfc_launch');

/// Owns both NFC entry points and routes them through the same logic:
///
/// - **App-launched-by-NFC** (Android intent → MainActivity → MethodChannel)
/// - **Foreground scan** (nfc_manager session, set via NfcService)
///
/// In both cases the flow is identical: look up the subject bound to the
/// tag, log the best chore for it, surface a snackbar.
///
/// Started once from `AppRoot` and lives for the app's lifetime.
class NfcLaunchHandler {
  final WidgetRef _ref;
  final GlobalKey<ScaffoldMessengerState> _messengerKey;
  bool _busy = false;

  NfcLaunchHandler(this._ref, this._messengerKey);

  Future<void> start() async {
    // App-launched-by-NFC path.
    _channel.setMethodCallHandler(_onCall);
    await _drainPending();

    // Foreground scan path — best-effort; some emulators report no NFC.
    final svc = _ref.read(nfcServiceProvider);
    final available = await svc.isAvailable();
    if (!available) return;
    svc.setHandler((tagId) => _handleTag(tagId));
    await svc.ensureStarted(onError: (_) {/* swallow */});
  }

  void stop() {
    _channel.setMethodCallHandler(null);
  }

  Future<void> _drainPending() async {
    try {
      final pending = await _channel.invokeMethod<String>('getPendingTag');
      if (pending != null && pending.isNotEmpty) {
        await _handleTag(pending);
      }
    } catch (_) {
      // Method not implemented (e.g. iOS / web) or platform error — ignore.
    }
  }

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'onTag') {
      final id = call.arguments;
      if (id is String && id.isNotEmpty) {
        await _handleTag(id);
      }
    }
  }

  Future<void> _handleTag(String tagId) async {
    if (_busy) return;
    _busy = true;
    try {
      final messenger = _messengerKey.currentState;
      // App-launched-by-NFC fires this before the providers have settled.
      // Awaiting `.future` waits for the auth → households → current chain
      // to resolve, instead of reading a transient null.
      final hh =
          await _ref.read(currentHouseholdControllerProvider.future);
      if (hh == null) {
        messenger?.showSnackBar(const SnackBar(
          showCloseIcon: true,
          duration: Duration(seconds: 5),
          content:
              Text('Sign in and pick a household to use NFC tags.'),
        ));
        return;
      }
      final subject =
          await _ref.read(subjectActionsProvider).findByNfcTag(tagId);
      if (subject == null) {
        messenger?.showSnackBar(SnackBar(
          showCloseIcon: true,
          duration: const Duration(seconds: 5),
          content:
              Text('Unknown tag $tagId — register it from a subject.'),
        ));
        return;
      }
      final result = await _ref
          .read(completionActionsProvider)
          .logBestChoreFor(subject.id, source: CompletionSource.nfc);
      if (result == null) {
        messenger?.showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('${subject.name}: nothing left for today.'),
        ));
        return;
      }
      // Wait for the post-log invalidation of the recent-completions list
      // to settle so the streak provider has the new completion in scope
      // before we read it.
      await _ref
          .read(recentCompletionsControllerProvider(subject.id).future);
      final streak = _ref.read(subjectStreakProvider(subject.id));

      // Success: push the celebration route via the router. NfcLaunchHandler
      // lives outside the widget tree so it has no BuildContext — the router
      // instance is the entry point. Re-tap on the chore row/chip undoes if
      // the user wants out; no snackbar Undo button needed.
      final character = CharacterRegistry.lookup(subject.icon);
      final whoName =
          _ref.read(authControllerProvider).valueOrNull?.displayName;
      _ref.read(appRouterProvider).push(
            Routes.celebration,
            extra: CelebrationArgs(
              character: character,
              choreName: result.chore.name,
              whoName: whoName,
              streak: streak,
            ),
          );
    } catch (e) {
      _messengerKey.currentState?.showSnackBar(SnackBar(
        showCloseIcon: true,
        duration: const Duration(seconds: 5),
        content: Text('NFC log failed: $e'),
      ));
    } finally {
      _busy = false;
    }
  }
}
