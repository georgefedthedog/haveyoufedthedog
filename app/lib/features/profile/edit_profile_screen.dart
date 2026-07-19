import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_state.dart';
import '../../core/profile/avatars.dart';
import '../../l10n/l10n.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/confirm_by_typing.dart';
import '../../widgets/labeled_field.dart';
import '../store/browse_packs_button.dart';
import 'avatar_picker.dart';
import 'debug_log_card.dart';
import 'language_card.dart';

/// Edit the current user's profile - avatar and name, with a dirty-tracked
/// Save - plus the instant-save language override and the debug-log dragon.
/// The NFC and notification settings live on the You tab; account deletion
/// is the app-bar action here.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _avatar;
  bool _seeded = false;
  bool _busy = false;

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
              const LanguageCard(),
              const SizedBox(height: 16),
              const DebugLogCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
