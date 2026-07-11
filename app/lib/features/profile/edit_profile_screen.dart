import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_state.dart';
import '../../core/diagnostics/debug_log.dart';
import '../../core/household/nfc_setting_highlight_controller.dart';
import '../../core/profile/avatars.dart';
import '../../core/storage/app_locale_controller.dart';
import '../../core/storage/nfc_tap_action_controller.dart';
import '../../l10n/l10n.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/confirm_by_typing.dart';
import '../../widgets/glow_highlight.dart';
import '../../widgets/labeled_field.dart';
import '../store/browse_packs_button.dart';
import 'avatar_picker.dart';

/// Endonyms for the language dropdown - each language named in itself, so
/// they are deliberately not localized.
const _languageNames = {
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
};

/// Edit the current user's profile - email is read-only, name is editable.
/// Also hosts the Log out action.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nfcGlowKey = GlobalKey<GlowHighlightState>();
  String? _avatar;
  bool _seeded = false;
  bool _busy = false;
  // Guards re-handling the same NFC-setting highlight request across rebuilds.
  bool _handled = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Anything actually changed vs the signed-in profile? The avatar
  /// baseline is the seeded value (stored avatar, or the carousel's
  /// first entry for never-picked users) so just opening the screen
  /// doesn't count as a change.
  bool _isDirty(AuthState auth) {
    final baselineAvatar = auth.avatar ?? AvatarRegistry.all.first.id;
    return _nameCtrl.text.trim() != (auth.displayName ?? '') ||
        _avatar != baselineAvatar;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(name: _nameCtrl.text.trim(), avatar: _avatar);
      // Land on the You tab (profile summary) rather than popping - pop
      // returns to wherever the edit was pushed from, which isn't always
      // where you want to admire the new avatar.
      if (mounted) router.go(Routes.youTab);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(l10n.commonCouldNotSave('$e')),
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Type-to-confirm, then delete. On success the authStore clears and the
  /// router's signedOut redirect takes over - no manual navigation.
  Future<void> _deleteAccount() async {
    final confirmed = await confirmByTyping(
      context,
      title: context.l10n.deleteAccountTitle,
      body: context.l10n.deleteAccountBody,
      actionLabel: context.l10n.deleteForever,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(l10n.couldNotDeleteAccount('$e')),
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(nfcSettingHighlightProvider.notifier).consume();
      final ctx = _nfcGlowKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          alignment: 0.2,
        );
      }
      _nfcGlowKey.currentState?.flash();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authControllerProvider);
    final auth = authAsync.valueOrNull;

    if (auth == null || !auth.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_seeded) {
      _nameCtrl.text = auth.displayName ?? '';
      // Fall back to the first registry avatar - the carousel opens with
      // it centred, and onChanged only fires on swipe, so a no-touch save
      // should store what's visibly selected.
      _avatar = auth.avatar ?? AvatarRegistry.all.first.id;
      _seeded = true;
    }

    // One-shot highlight requested from a subject's NFC card (mirrors the
    // Home→You act-as cue): flash the tap-behaviour setting into view. Only
    // act once it's actually showing; consuming resets the guard for next time.
    final wantNfcHighlight = ref.watch(nfcSettingHighlightProvider);
    if (wantNfcHighlight && !_handled) {
      _handled = true;
      _handleHighlight();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.editProfileTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.deleteAccountTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : _deleteAccount,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AbsorbPointer(
                absorbing: _busy,
                child: AvatarPicker(
                  selected: _avatar,
                  onChanged: (id) => setState(() => _avatar = id),
                ),
              ),
              BrowsePacksButton(label: context.l10n.browseMoreAvatars),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: context.l10n.displayNameLabel,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            hintText: context.l10n.profileNameHint,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? context.l10n.commonRequired
                              : null,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _save(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: context.l10n.authEmailLabel,
                        child: TextFormField(
                          key: const ValueKey('email-field'),
                          initialValue: auth.email ?? '',
                          readOnly: true,
                          decoration: InputDecoration(
                            helperText: context.l10n.emailCantChange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(context.l10n.commonSaveChanges),
                        onPressed: (_isDirty(auth) && !_busy) ? _save : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      final stored = ref
                          .watch(appLocaleControllerProvider)
                          .valueOrNull
                          ?.languageCode;
                      return LabeledField(
                        label: context.l10n.profileLanguageLabel,
                        child: DropdownButtonFormField<String>(
                          // Recreate when the stored value changes so a
                          // late prefs load still shows the right pick.
                          key: ValueKey('language-${stored ?? ''}'),
                          initialValue: stored ?? '',
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(
                                context.l10n.profileLanguageSystemDefault,
                              ),
                            ),
                            for (final locale
                                in AppLocalizations.supportedLocales)
                              DropdownMenuItem(
                                value: locale.languageCode,
                                child: Text(
                                  _languageNames[locale.languageCode] ??
                                      locale.languageCode,
                                ),
                              ),
                          ],
                          // Saves immediately - device preference, not
                          // part of the profile Save.
                          onChanged: _busy
                              ? null
                              : (code) => ref
                                    .read(appLocaleControllerProvider.notifier)
                                    .setLocale(
                                      (code == null || code.isEmpty)
                                          ? null
                                          : Locale(code),
                                    ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlowHighlight(
                key: _nfcGlowKey,
                borderRadius: 20,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        final scheme = theme.colorScheme;
                        final completesChore =
                            ref
                                .watch(nfcTapActionControllerProvider)
                                .valueOrNull ??
                            true;
                        // Mirrors the invite card's header row on household
                        // details: icon, titleSmall + bodySmall copy, switch.
                        return Row(
                          children: [
                            const Icon(Icons.nfc),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.nfcCompleteOnTap,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    completesChore
                                        ? context.l10n.nfcTapCompletesDesc
                                        : context.l10n.nfcTapOpensDesc,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: completesChore,
                              // Saves immediately - device preference, not
                              // part of the profile Save.
                              onChanged: _busy
                                  ? null
                                  : (v) => ref
                                        .read(
                                          nfcTapActionControllerProvider
                                              .notifier,
                                        )
                                        .setCompletesChore(v),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _DebugLogCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

/// TEMPORARY: the live on-device debug log (all `debugPrint` output, captured
/// via [installDebugLogCapture]) so we can read logs on a console-less
/// TestFlight build. Hidden behind a "Here be dragons" link so it's out of the
/// way for normal use; tap to reveal. Newest line first, fixed-height scroll,
/// capped buffer. Copy shares the whole log; Clear empties it for a fresh
/// repro. Remove once no longer needed.
class _DebugLogCard extends StatefulWidget {
  const _DebugLogCard();

  @override
  State<_DebugLogCard> createState() => _DebugLogCardState();
}

class _DebugLogCardState extends State<_DebugLogCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_revealed) {
      return Center(
        child: TextButton.icon(
          onPressed: () => setState(() => _revealed = true),
          icon: const Text('🐉'),
          label: Text(
            'Here be dragons',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: debugLog,
          builder: (context, lines, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Debug log (${lines.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: lines.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: lines.join('\n')),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied')),
                              );
                            },
                    ),
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: lines.isEmpty
                          ? null
                          : () => debugLog.value = const [],
                    ),
                    IconButton(
                      tooltip: 'Hide',
                      icon: const Icon(Icons.expand_less, size: 18),
                      onPressed: () => setState(() => _revealed = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (lines.isEmpty)
                  Text('No debug output yet.', style: theme.textTheme.bodySmall)
                else
                  SizedBox(
                    height: 260,
                    child: Scrollbar(
                      child: ListView.builder(
                        primary: false,
                        itemCount: lines.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          // Newest first.
                          child: Text(
                            lines[lines.length - 1 - i],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
