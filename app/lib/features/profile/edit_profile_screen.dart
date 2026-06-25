import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_state.dart';
import '../../core/notifications/fcm_token_sync.dart';
import '../../core/profile/avatars.dart';
import '../../core/storage/nfc_tap_action_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/confirm_by_typing.dart';
import '../../widgets/labeled_field.dart';
import '../store/browse_packs_button.dart';
import 'avatar_picker.dart';

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
        SnackBar(showCloseIcon: true, content: Text('Could not save: $e')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Type-to-confirm, then delete. On success the authStore clears and the
  /// router's signedOut redirect takes over - no manual navigation.
  Future<void> _deleteAccount() async {
    final confirmed = await confirmByTyping(
      context,
      title: 'Delete your account?',
      body:
          'This permanently deletes your account and signs you out. '
          'Chores you completed stay with your household, without '
          'your name on them. Households left with nobody in them '
          'are deleted entirely.\n\nThis cannot be undone.',
      actionLabel: 'Delete forever',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text('Could not delete account: $e'),
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
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            tooltip: 'Delete account',
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
              const BrowsePacksButton(label: 'Get more avatars'),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: 'Display name',
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'How others in your household see you',
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _save(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Email',
                        child: TextFormField(
                          key: const ValueKey('email-field'),
                          initialValue: auth.email ?? '',
                          readOnly: true,
                          decoration: const InputDecoration(
                            helperText: "Email can't be changed.",
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Save changes'),
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
                                  'Complete chore on tap',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  completesChore
                                      ? 'Tapping a tag completes the current chore.'
                                      : "Tapping a tag opens the thing's page.",
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
                                        nfcTapActionControllerProvider.notifier,
                                      )
                                      .setCompletesChore(v),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _FcmDebugCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

/// TEMPORARY: shows the live push-token diagnostics captured by
/// [fcmDebugLog] so we can see, on a TestFlight phone, where iOS token
/// registration breaks. Tap "Copy" to share the log. Remove once iOS push
/// is confirmed working.
class _FcmDebugCard extends StatelessWidget {
  const _FcmDebugCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: fcmDebugLog,
          builder: (context, lines, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Push diagnostics',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
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
                  ],
                ),
                const SizedBox(height: 8),
                if (lines.isEmpty)
                  Text(
                    'No diagnostics captured yet.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
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
