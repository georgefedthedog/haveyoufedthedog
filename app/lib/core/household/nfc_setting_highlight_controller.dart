import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nfc_setting_highlight_controller.g.dart';

/// One-shot signal asking the You tab's NFC card to flash its "Complete chore
/// on tap" setting into view. Set when the "the You tab" link in a subject's
/// NFC-tag card is tapped (which navigates to the You tab); the setting card
/// consumes it once it has flashed.
///
/// Kept alive so the flag survives the gap between the tap and the You tab
/// first building - mirrors [ActAsHighlight] for the Home→You cue.
@Riverpod(keepAlive: true)
class NfcSettingHighlight extends _$NfcSettingHighlight {
  @override
  bool build() => false;

  /// Request the highlight - call right before navigating to the You tab.
  void request() => state = true;

  /// Clear the flag once the setting has flashed.
  void consume() => state = false;
}
