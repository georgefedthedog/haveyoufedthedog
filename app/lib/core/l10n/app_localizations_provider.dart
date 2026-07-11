import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../l10n/l10n.dart';
import '../storage/app_locale_controller.dart';

part 'app_localizations_provider.g.dart';

/// The resolved [AppLocalizations] for code that has no BuildContext
/// (notification channel names, NFC-launch snackbars). Widgets keep using
/// `context.l10n` - never watch this from inside the widget tree.
///
/// Reads the device locale once per build; a device-language change
/// relaunches the activity on both platforms, so no listener is needed.
@Riverpod(keepAlive: true)
AppLocalizations appLocalizations(Ref ref) {
  final override = ref.watch(appLocaleControllerProvider).valueOrNull;
  final locale = override ?? PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );
  return lookupAppLocalizations(
    supported ? Locale(locale.languageCode) : const Locale('en'),
  );
}
