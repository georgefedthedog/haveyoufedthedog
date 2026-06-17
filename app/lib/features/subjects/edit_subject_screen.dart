import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/nfc_tap_action_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_actions.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/drop_target_circle.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/wiggle.dart';
import '../nfc/nfc_scan_dialog.dart';
import '../store/browse_packs_button.dart';
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
  // Defaults to the first registry character so a created subject matches
  // what the carousel visibly shows - onChanged only fires on swipe, so
  // without this a no-touch save would store null (→ generic).
  String? _icon = CharacterRegistry.all.first.id;
  String? _nfcTagId;
  bool _seeded = false;
  bool _busy = false;

  // Tapping the Register/Remove target pokes this; the tag chip wiggles to
  // reveal it's dragged across to bind/unbind.
  final _wiggle = WiggleController();

  bool get _isEdit => widget.subjectId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wiggle.dispose();
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
        await ref
            .read(subjectActionsProvider)
            .updateSubject(widget.subjectId!, nfcTagId: tagId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              showCloseIcon: true,
              content: Text('Could not save tag: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _removeTag() async {
    final name = _nameCtrl.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove tag?'),
        content: Text(
          'Tapping it will no longer reach '
          '${name.isEmpty ? "this friend" : name}. You can bind it again '
          'any time by re-scanning.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _nfcTagId = null);
    if (_isEdit) {
      try {
        await ref
            .read(subjectActionsProvider)
            .updateSubject(widget.subjectId!, clearNfcTag: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              showCloseIcon: true,
              content: Text('Could not remove tag: $e'),
            ),
          );
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
        await actions.updateSubject(widget.subjectId!, name: name, icon: _icon);
        if (mounted) router.pop();
      } else {
        final created = await actions.createSubject(name: name, icon: _icon);
        // If the user scanned a tag during a new-subject flow, bind it now.
        if (_nfcTagId != null) {
          await actions.updateSubject(created.id, nfcTagId: _nfcTagId);
        }
        // Wait for the invalidated subjects list to refetch so the detail
        // screen finds the new record immediately - otherwise the screen's
        // "subject missing → bounce to home" guard fires on the stale list.
        await ref.read(subjectsControllerProvider.future);
        // Drop the user on the new subject's detail page so they can add
        // chores immediately. `pushReplacement` swaps this create form out
        // of the stack - Back from detail goes to home, not back into the
        // (now-stale) form.
        if (mounted) {
          router.pushReplacement(Routes.subjectDetail(created.id));
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not save: $e')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_nameCtrl.text}?'),
        content: const Text(
          'All chores and history for this friend will be permanently '
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
      // Jump to home instead of popping - popping would land on the
      // subject detail screen which would then notice the subject is gone
      // and show a "no longer exists" page.
      if (mounted) router.go(Routes.home);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not delete: $e')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Anything actually changed vs the stored subject? Creation counts as
  /// dirty once a name is typed. An empty name never enables Save.
  bool _isDirty(Subject? existing) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return false;
    if (!_isEdit) return true;
    if (existing == null) return false;
    return name != existing.name || _icon != existing.icon;
  }

  @override
  Widget build(BuildContext context) {
    // For edit mode, fish the existing subject out of the household list.
    Subject? existing;
    if (_isEdit) {
      final asyncSubjects = ref.watch(subjectsControllerProvider);
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
      // throwing - the screen will unmount in a frame or two.
      if (existing == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _seedFromExisting(existing);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit friend' : 'New friend'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete friend',
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
              const BrowsePacksButton(label: 'Get more characters'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: 'Name',
                        child: TextField(
                          controller: _nameCtrl,
                          autofocus: !_isEdit,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Kiko',
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(_isEdit ? Icons.check : Icons.pets),
                        label: Text(_isEdit ? 'Save changes' : 'Add friend'),
                        onPressed: (_busy || !_isDirty(existing))
                            ? null
                            : _save,
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

                      // Both states share the drag mechanic: carry the tag
                      // chip into the dashed circle - purple "Register"
                      // (starts the scan) when unbound, red "Remove" bin
                      // when bound. Same gesture as members and chores.
                      final bound = _nfcTagId != null;
                      final tagChip = Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primaryContainer,
                            ),
                            child: Icon(
                              Icons.nfc,
                              size: 24,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tag',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );

                      final title = bound
                          ? 'Tag registered'
                          : 'No tag registered';
                      final subtitle = bound
                          ? (completesChore
                                ? 'On this phone, a tap ticks off the '
                                      'current chore. Change this setting in '
                                      'Edit Profile.'
                                : "On this phone, a tap opens this friend's "
                                      'page. Change this setting in '
                                      'Edit Profile.')
                          : 'Drag the tag to bind one to '
                                '${_nameCtrl.text.trim().isEmpty ? "this friend" : _nameCtrl.text.trim()}.';
                      final targetBase = bound
                          ? Colors.red.shade300
                          : scheme.primary;
                      final targetHover = bound ? Colors.red : scheme.primary;
                      final targetIcon = bound
                          ? Icons.delete_outline
                          : Icons.add;
                      final targetLabel = bound ? 'Remove' : 'Register';

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Wiggle(
                            controller: _wiggle,
                            child: LongPressDraggable<String>(
                              data: _nfcTagId ?? 'register',
                              feedback: Material(
                                color: Colors.transparent,
                                child: tagChip,
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: tagChip,
                              ),
                              child: tagChip,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropTargetCircle<String>(
                            icon: targetIcon,
                            label: targetLabel,
                            baseColor: targetBase,
                            hoverColor: targetHover,
                            enabled: !_busy,
                            onDrop: (_) =>
                                bound ? _removeTag() : _scanAndBindTag(),
                            onTap: _wiggle.poke,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
