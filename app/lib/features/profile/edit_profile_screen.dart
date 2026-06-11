import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_state.dart';
import '../../core/profile/avatars.dart';
import '../../core/storage/nfc_tap_action_controller.dart';
import '../../widgets/build_label.dart';
import '../../widgets/labeled_field.dart';
import 'avatar_picker.dart';

/// Edit the current user's profile — email is read-only, name is editable.
/// Also hosts the Log out action.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
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
      if (mounted) router.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('Could not save: $e'),
      ));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authControllerProvider);
    final auth = authAsync.valueOrNull;

    if (auth == null || !auth.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_seeded) {
      _nameCtrl.text = auth.displayName ?? '';
      // Fall back to the first registry avatar — the carousel opens with
      // it centred, and onChanged only fires on swipe, so a no-touch save
      // should store what's visibly selected.
      _avatar = auth.avatar ?? AvatarRegistry.all.first.id;
      _seeded = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
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
                            hintText:
                                'How others in your household see you',
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
                  child: Builder(builder: (context) {
                    final theme = Theme.of(context);
                    final scheme = theme.colorScheme;
                    final completesChore = ref
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
                              Text('Complete chore on tap',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700)),
                              Text(
                                completesChore
                                    ? 'Tapping a tag completes the current chore.'
                                    : "Tapping a tag opens the friend's page.",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: completesChore,
                          // Saves immediately — device preference, not
                          // part of the profile Save.
                          onChanged: _busy
                              ? null
                              : (v) => ref
                                  .read(nfcTapActionControllerProvider
                                      .notifier)
                                  .setCompletesChore(v),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
