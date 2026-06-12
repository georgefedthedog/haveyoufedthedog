import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_preferences_provider.dart';

part 'nfc_tap_action_controller.g.dart';

/// Per-device preference for what an NFC tag tap does:
///
/// - **true** (default) - complete the closest due chore for the bound
///   subject, with the celebration overlay. The original behaviour.
/// - **false** - just open the subject's detail screen.
///
/// Lives in SharedPreferences (each phone configures its own tap
/// behaviour) and is toggled from the Edit Profile screen.
@Riverpod(keepAlive: true)
class NfcTapActionController extends _$NfcTapActionController {
  static const _key = 'nfc_tap_completes_chore';

  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? true;
  }

  Future<void> setCompletesChore(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, value);
    state = AsyncData(value);
  }
}
