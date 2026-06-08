import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_actions.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../widgets/build_label.dart';
import 'icon_picker.dart';

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
    _seeded = true;
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
          clearIcon: _icon == null,
        );
      } else {
        await actions.createSubject(name: name, icon: _icon);
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
              Text('Icon', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              IconPicker(
                selected: _icon,
                onChanged: (token) => setState(() => _icon = token),
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
