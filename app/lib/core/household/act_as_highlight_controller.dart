import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'act_as_highlight_controller.g.dart';

/// One-shot signal asking the You tab's "Whose turn?" card to flash itself
/// into view. Set when the home members row taps a managed member (which
/// navigates to the You tab); the card consumes it once it has flashed.
///
/// Kept alive so the flag survives the gap between the tap and the You tab
/// first building - the tab is a lazily-built nav branch, so a plain
/// `ref.listen` would miss a signal raised before it mounts.
@Riverpod(keepAlive: true)
class ActAsHighlight extends _$ActAsHighlight {
  @override
  bool build() => false;

  /// Request the highlight - call right before navigating to the You tab.
  void request() => state = true;

  /// Clear the flag once the card has flashed.
  void consume() => state = false;
}
