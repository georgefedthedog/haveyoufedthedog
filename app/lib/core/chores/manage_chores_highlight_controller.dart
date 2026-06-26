import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_chores_highlight_controller.g.dart';

/// One-shot signal asking the Edit thing screen to flash its "Manage chores"
/// section into view. Set when the "Manage chores" link below a subject's
/// today-list is tapped (which navigates to Edit thing); the section consumes
/// it once it has flashed.
///
/// Kept alive so the flag survives the gap between the tap and Edit thing first
/// building - mirrors NfcSettingHighlight.
@Riverpod(keepAlive: true)
class ManageChoresHighlight extends _$ManageChoresHighlight {
  @override
  bool build() => false;

  /// Request the highlight - call right before navigating to Edit thing.
  void request() => state = true;

  /// Clear the flag once the section has flashed.
  void consume() => state = false;
}
