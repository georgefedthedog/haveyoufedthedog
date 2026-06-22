import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_deep_link.g.dart';

/// The two kinds of deep link the app understands.
enum DeepLinkKind {
  /// `https://haveyoufedthedog.com/join?code=...` - join a household.
  join,

  /// `https://haveyoufedthedog.com/claim?code=...` - claim a managed member.
  claim,
}

/// A deep link captured before the app could act on it, held until the
/// routing phase is right to consume it. Two deferred cases need this:
///  - a **claim** link tapped while signed out - the sign-up screen
///    (`AuthLandingScreen`) reads it and opens pre-filled in claim mode, and
///  - a **join** link tapped while signed out - replayed by `AppRoot` once the
///    user authenticates and the phase reaches `needsToPick`/`ready`.
///
/// A join link tapped while already signed in skips this entirely (it routes
/// straight to the Join form); a claim link while signed in is rejected with a
/// snackbar - neither sets a pending link.
class PendingDeepLink {
  const PendingDeepLink({required this.kind, required this.code});

  final DeepLinkKind kind;
  final String code;
}

/// Holds the single pending deep link (or null). `keepAlive` so it survives
/// the provider churn of the signed-out -> signed-in transition without being
/// disposed before the link can be replayed.
@Riverpod(keepAlive: true)
class PendingDeepLinkController extends _$PendingDeepLinkController {
  @override
  PendingDeepLink? build() => null;

  void set(PendingDeepLink link) => state = link;

  void clear() => state = null;
}
