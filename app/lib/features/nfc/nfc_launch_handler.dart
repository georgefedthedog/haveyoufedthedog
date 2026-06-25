import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/completion_actions.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/household/acting_user_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/households_controller.dart';
import '../../core/nfc/nfc_service.dart';
import '../../core/storage/nfc_tap_action_controller.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_actions.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../completions/celebration_args.dart';

/// Logs a chore when an NFC tag is tapped.
///
/// Tags carry a `/nfc-tap?household=…&subject=…` universal link. The OS opens
/// the app to it (cold / warm / foreground, both platforms), `DeepLinkHandler`
/// parks it, and `AppRoot` routes it here via [handleNfcTap]. That single
/// OS-deep-link path replaced the old per-platform tag *reading* (UID lookup +
/// Android intent channel).
///
/// Constructed once by `AppRoot`.
class NfcLaunchHandler {
  final WidgetRef _ref;
  final GlobalKey<ScaffoldMessengerState> _messengerKey;
  bool _busy = false;

  NfcLaunchHandler(this._ref, this._messengerKey);

  /// `/nfc-tap?household=<hid>&subject=<sid>`. Switches to the tag's household
  /// first if the tapper is a member - so a multi-household member (e.g. a dog
  /// walker) can tap any house's tag without manually switching - then logs via
  /// the shared flow. The server also gates the completion to members, so a
  /// non-member can't log regardless. An empty [householdId] falls back to the
  /// current house.
  Future<void> handleNfcTap(String householdId, String subjectId) async {
    if (_busy) return;
    // A tag we *just* wrote is usually still on the phone; ignore its instant
    // self-tap so writing a tag doesn't immediately log a chore.
    if (nfcTapJustWritten) {
      debugPrint('NFC: tap ignored - tag was just written.');
      return;
    }
    final messenger = _messengerKey.currentState;
    try {
      if (householdId.isNotEmpty) {
        final households = await _ref.read(householdsControllerProvider.future);
        if (!households.any((h) => h.id == householdId)) {
          messenger?.showSnackBar(
            const SnackBar(
              showCloseIcon: true,
              duration: Duration(seconds: 5),
              content: Text("You're not a member of this tag's household."),
            ),
          );
          return;
        }
        final current = await _ref.read(
          currentHouseholdControllerProvider.future,
        );
        if (current?.id != householdId) {
          await _ref
              .read(currentHouseholdControllerProvider.notifier)
              .setCurrent(householdId);
        }
      }
      await _run(
        (actions) => actions.findById(subjectId),
        notFound: "That tag points to something that isn't in this household.",
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          duration: const Duration(seconds: 5),
          content: Text('NFC log failed: $e'),
        ),
      );
    }
  }

  /// Resolve the subject via [resolve], then (per the tap preference) open its
  /// page or log its best chore and celebrate.
  Future<void> _run(
    Future<Subject?> Function(SubjectActions actions) resolve, {
    required String notFound,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      final messenger = _messengerKey.currentState;
      // A cold-launch tap fires this before the providers have settled.
      // Awaiting `.future` waits for the auth → households → current chain
      // to resolve, instead of reading a transient null.
      final hh = await _ref.read(currentHouseholdControllerProvider.future);
      if (hh == null) {
        messenger?.showSnackBar(
          const SnackBar(
            showCloseIcon: true,
            duration: Duration(seconds: 5),
            content: Text('Sign in and pick a household to use NFC tags.'),
          ),
        );
        return;
      }
      final subject = await resolve(_ref.read(subjectActionsProvider));
      if (subject == null) {
        messenger?.showSnackBar(
          SnackBar(
            showCloseIcon: true,
            duration: const Duration(seconds: 5),
            content: Text(notFound),
          ),
        );
        return;
      }
      // Per-device preference: a tap either completes the closest chore
      // (default) or just opens the thing's page.
      final completesChore = await _ref.read(
        nfcTapActionControllerProvider.future,
      );
      if (!completesChore) {
        _ref.read(appRouterProvider).push(Routes.subjectDetail(subject.id));
        return;
      }
      final result = await _ref
          .read(completionActionsProvider)
          .logBestChoreFor(subject.id, source: CompletionSource.nfc);
      if (result == null) {
        messenger?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text('${subject.name}: nothing left for today.'),
          ),
        );
        return;
      }
      // Wait for the post-log invalidation of the recent-completions list
      // to settle so the streak provider has the new completion in scope
      // before we read it.
      await _ref.read(recentCompletionsControllerProvider(subject.id).future);
      final streak = _ref.read(subjectStreakProvider(subject.id));

      // Success: push the celebration route via the router. NfcLaunchHandler
      // lives outside the widget tree so it has no BuildContext - the router
      // instance is the entry point. Re-tap on the chore row/chip undoes if
      // the user wants out; no snackbar Undo button needed.
      final character = _ref.read(catalogProvider).lookupCharacter(subject.icon);
      // An NFC tap credits whoever you're acting as (same as a chip tap).
      final actingMember = await _ref.read(actingMemberProvider.future);
      _ref
          .read(appRouterProvider)
          .push(
            Routes.celebration,
            extra: CelebrationArgs(
              character: character,
              choreName: result.chore.name,
              whoName: actingMember?.displayName,
              whoAvatar: actingMember?.avatar,
              streak: streak,
            ),
          );
    } catch (e) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          duration: const Duration(seconds: 5),
          content: Text('NFC log failed: $e'),
        ),
      );
    } finally {
      _busy = false;
    }
  }
}
