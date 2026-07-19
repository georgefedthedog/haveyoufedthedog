import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_locale_controller.dart';
import '../../l10n/l10n.dart';

/// Flag + endonym for the language dropdown - each language named in itself,
/// so they are deliberately not localized; the flags make the headerless
/// card read as a language picker at a glance.
const _languageNames = {
  'en': '🇬🇧  English',
  'de': '🇩🇪  Deutsch',
  'fr': '🇫🇷  Français',
  'es': '🇪🇸  Español',
};

/// The per-device app-language override, shown on Edit Profile. Saves
/// instantly via [appLocaleControllerProvider] (not part of the profile
/// Save); "System default" follows the phone's language.
class LanguageCard extends ConsumerWidget {
  const LanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stored = ref
        .watch(appLocaleControllerProvider)
        .valueOrNull
        ?.languageCode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          // Recreate when the stored value changes so a late prefs load
          // still shows the right pick.
          key: ValueKey('language-${stored ?? ''}'),
          initialValue: stored ?? '',
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(context.l10n.profileLanguageSystemDefault),
            ),
            for (final locale in AppLocalizations.supportedLocales)
              DropdownMenuItem(
                value: locale.languageCode,
                child: Text(
                  _languageNames[locale.languageCode] ?? locale.languageCode,
                ),
              ),
          ],
          onChanged: (code) => ref
              .read(appLocaleControllerProvider.notifier)
              .setLocale(
                (code == null || code.isEmpty) ? null : Locale(code),
              ),
        ),
      ),
    );
  }
}
