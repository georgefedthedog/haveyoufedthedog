import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_actions.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../nfc/nfc_scan_dialog.dart';
import 'character_carousel.dart';

/// Create or edit a [Subject]. When [subjectId] is null we're creating;
/// when it's set we look the subject up in the household-wide list and
/// pre-fill the form.
class EditSubjectScreen extends ConsumerStatefulWidget {
  /// Null means "create a new subject."
  final String? subjectId;

  const EditSubjectScreen({super.key, this.subjectId});

  @override
  ConsumerState<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends ConsumerState<EditSubjectScreen> {
  final _nameCtrl = TextEditingController();
  String? _icon;
  String? _nfcTagId;
  bool _seeded = false;
  bool _busy = false;

  bool get _isEdit => widget.subjectId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Seed form fields from the existing subject the first time it's
  /// available. Done here rather than in initState because the subjects
  /// list comes from an async provider.
  void _seedFromExisting(Subject existing) {
    if (_seeded) return;
    _nameCtrl.text = existing.name;
    _icon = existing.icon;
    _nfcTagId = existing.nfcTagId;
    _seeded = true;
  }

  Future<void> _scanAndBindTag() async {
    final tagId = await showDialog<String>(
      context: context,
      builder: (_) => const NfcScanDialog(),
    );
    if (tagId == null || tagId.isEmpty || !mounted) return;
    setState(() => _nfcTagId = tagId);
    if (_isEdit) {
      // Save immediately so the binding takes effect even if the user
      // backs out without hitting Save.
      try {
        await ref.read(subjectActionsProvider).updateSubject(
              widget.subjectId!,
              nfcTagId: tagId,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            showCloseIcon: true,
            content: Text('Could not save tag: $e'),
          ));
        }
      }
    }
  }

  Future<void> _removeTag() async {
    setState(() => _nfcTagId = null);
    if (_isEdit) {
      try {
        await ref.read(subjectActionsProvider).updateSubject(
              widget.subjectId!,
              clearNfcTag: true,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            showCloseIcon: true,
            content: Text('Could not remove tag: $e'),
          ));
        }
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final actions = ref.read(subjectActionsProvider);
      if (_isEdit) {
        await actions.updateSubject(
          widget.subjectId!,
          name: name,
          icon: _icon,
        );
        if (mounted) router.pop();
      } else {
        final created = await actions.createSubject(name: name, icon: _icon);
        // If the user scanned a tag during a new-subject flow, bind it now.
        if (_nfcTagId != null) {
          await actions.updateSubject(created.id, nfcTagId: _nfcTagId);
        }
        // Wait for the invalidated subjects list to refetch so the detail
        // screen finds the new record immediately — otherwise the screen's
        // "subject missing → bounce to home" guard fires on the stale list.
        await ref.read(subjectsControllerProvider.future);
        // Drop the user on the new subject's detail page so they can add
        // chores immediately. `pushReplacement` swaps this create form out
        // of the stack — Back from detail goes to home, not back into the
        // (now-stale) form.
        if (mounted) {
          router.pushReplacement(Routes.subjectDetail(created.id));
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('Could not save: $e'),
      ));
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_nameCtrl.text}?'),
        content: const Text(
          'All chores and history for this subject will be permanently '
          'removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(subjectActionsProvider).deleteSubject(widget.subjectId!);
      // Wait for the invalidated subjects list to refetch so the home
      // screen doesn't flash the just-deleted subject before the cache
      // catches up.
      await ref.read(subjectsControllerProvider.future);
      // Jump to home instead of popping — popping would land on the
      // subject detail screen which would then notice the subject is gone
      // and show a "no longer exists" page.
      if (mounted) router.go(Routes.home);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('Could not delete: $e'),
      ));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // For edit mode, fish the existing subject out of the household list.
    if (_isEdit) {
      final asyncSubjects = ref.watch(subjectsControllerProvider);
      Subject? existing;
      final list = asyncSubjects.valueOrNull;
      if (list != null) {
        for (final s in list) {
          if (s.id == widget.subjectId) {
            existing = s;
            break;
          }
        }
      }
      // Either still loading, or the subject was just deleted under us and
      // we're mid-navigation back to home. Show a spinner instead of
      // throwing — the screen will unmount in a frame or two.
      if (existing == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      _seedFromExisting(existing);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit subject' : 'New subject'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete subject',
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IgnorePointer(
                ignoring: _busy,
                child: CharacterCarousel(
                  selected: _icon,
                  onChanged: (id) => setState(() => _icon = id),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                autofocus: !_isEdit,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Kiko',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text('NFC tag',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.nfc),
                  title: Text(
                    _nfcTagId == null
                        ? 'No tag registered'
                        : 'Bound: $_nfcTagId',
                    style: _nfcTagId == null
                        ? null
                        : const TextStyle(fontFamily: 'monospace'),
                  ),
                  subtitle: Text(
                    _nfcTagId == null
                        ? 'Bind a tag to quick-log by tapping your phone.'
                        : 'Tap this subject by holding the tag near your phone.',
                  ),
                  trailing: _nfcTagId == null
                      ? TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Register'),
                          onPressed: _busy ? null : _scanAndBindTag,
                        )
                      : IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Remove tag',
                          onPressed: _busy ? null : _removeTag,
                        ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isEdit ? 'Save changes' : 'Add subject'),
                onPressed: (_busy || _nameCtrl.text.trim().isEmpty)
                    ? null
                    : _save,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
