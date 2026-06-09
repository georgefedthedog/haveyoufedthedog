import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_actions.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../widgets/build_label.dart';
import '../nfc/nfc_scan_dialog.dart';
import 'character_picker.dart';

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
      } else {
        final created = await actions.createSubject(name: name, icon: _icon);
        // If the user scanned a tag during a new-subject flow, bind it now.
        if (_nfcTagId != null) {
          await actions.updateSubject(created.id, nfcTagId: _nfcTagId);
        }
      }
      if (mounted) router.pop();
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
      if (mounted) router.pop();
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
      final existing = asyncSubjects.valueOrNull?.firstWhere(
        (s) => s.id == widget.subjectId,
        orElse: () => throw StateError('Subject ${widget.subjectId} missing'),
      );
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
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipOval(
                    child: CharacterArtwork(
                      character: CharacterRegistry.lookup(_icon),
                      stage: true,
                      iconSize: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                autofocus: !_isEdit,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Kiko',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text('Character',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              CharacterPicker(
                selected: _icon,
                onChanged: (id) => setState(() => _icon = id),
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
                icon: const Icon(Icons.check),
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
