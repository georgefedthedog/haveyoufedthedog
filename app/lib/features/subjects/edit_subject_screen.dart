import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chore_actions.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/chores/manage_chores_highlight_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/nfc_setting_highlight_controller.dart';
import '../../core/storage/nfc_tap_action_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_actions.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../../widgets/glow_highlight.dart';
import '../../widgets/labeled_field.dart';
import '../nfc/nfc_write_dialog.dart';
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
  bool _seeded = false;
  bool _busy = false;
  // "A tag has been written for this subject" - drives the linked indicator.
  bool _hasTag = false;

  // One-shot "Manage chores" glow, requested from the subject's View page.
  final _manageChoresGlowKey = GlobalKey<GlowHighlightState>();
  bool _handledChoresHighlight = false;

  // Tappable "Edit Profile" link in the tag card subtitle - owned here so it
  // can be disposed.
  late final TapGestureRecognizer _editProfileTap;

  bool get _isEdit => widget.subjectId != null;

  @override
  void initState() {
    super.initState();
    _editProfileTap = TapGestureRecognizer()
      ..onTap = () {
        ref.read(nfcSettingHighlightProvider.notifier).request();
        context.push(Routes.profile);
      };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _editProfileTap.dispose();
    super.dispose();
  }

  /// Seed form fields from the existing subject the first time it's
  /// available. Done here rather than in initState because the subjects
  /// list comes from an async provider.
  void _seedFromExisting(Subject existing) {
    if (_seeded) return;
    _nameCtrl.text = existing.name;
    _icon = existing.icon;
    _hasTag = existing.nfcTagId != null;
    _seeded = true;
  }

  /// Scroll the Manage chores section into view and pulse its glow - the
  /// "look here" cue after arriving from the View page's "Manage chores" link.
  void _handleChoresHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(manageChoresHighlightProvider.notifier).consume();
      final ctx = _manageChoresGlowKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          alignment: 0.1,
        );
      }
      _manageChoresGlowKey.currentState?.flash();
    });
  }

  /// Write the subject's `/nfc-tap` universal link to a physical tag. Edit mode
  /// only (we need the subject id). The URL carries the current household so a
  /// tap logs against the right house even for multi-household members.
  Future<void> _writeTag() async {
    final hid = ref.read(currentHouseholdControllerProvider).valueOrNull?.id;
    if (hid == null || widget.subjectId == null) return;
    final url =
        'https://haveyoufedthedog.com/nfc-tap'
        '?household=$hid&subject=${widget.subjectId}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NfcWriteDialog(url: url),
    );
    if (ok != true || !mounted) return;
    setState(() => _hasTag = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(subjectActionsProvider).setNfcTag(widget.subjectId!, url);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not save tag: $e')),
      );
    }
  }

  Future<void> _forgetTag() async {
    setState(() => _hasTag = false);
    try {
      await ref.read(subjectActionsProvider).clearNfcTag(widget.subjectId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(showCloseIcon: true, content: Text('Could not forget: $e')),
        );
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
        // Wait for the invalidated subjects list to refetch so the edit
        // screen finds the new record immediately - otherwise its
        // "subject missing → spinner" guard fires on the stale list.
        await ref.read(subjectsControllerProvider.future);
        // Drop the user on the new subject's edit page so they can add chores
        // straight away - "Manage chores" lives there now. `pushReplacement`
        // swaps this create form out of the stack, so Back goes to home, not
        // back into the (now-stale) form.
        if (mounted) {
          router.pushReplacement(Routes.subjectEdit(created.id));
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
          'All chores and history for this thing will be permanently '
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

    // Per-device tap behaviour, surfaced in the tag card subtitle.
    final completesChore =
        ref.watch(nfcTapActionControllerProvider).valueOrNull ?? true;

    // One-shot highlight requested from the View page's "Manage chores" link:
    // flash that section into view once it's actually showing. Consuming on
    // play resets the guard for next time.
    final wantChoresHighlight = ref.watch(manageChoresHighlightProvider);
    if (wantChoresHighlight && !_handledChoresHighlight) {
      _handledChoresHighlight = true;
      _handleChoresHighlight();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit thing' : 'New thing'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete thing',
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
              const BrowsePacksButton(label: 'Get more characters →'),
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
                        label: Text(_isEdit ? 'Save changes' : 'Add thing'),
                        onPressed: (_busy || !_isDirty(existing))
                            ? null
                            : _save,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 16),
                GlowHighlight(
                  key: _manageChoresGlowKey,
                  borderRadius: 20,
                  child: _ChoresSection(subjectId: widget.subjectId!),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        final scheme = theme.colorScheme;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.nfc, color: scheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _hasTag ? 'Tag written' : 'No tag yet',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      if (_hasTag)
                                        Text.rich(
                                          TextSpan(
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                            children: [
                                              TextSpan(
                                                text: completesChore
                                                    ? 'On this phone, a tap ticks off the current chore. Change this in '
                                                    : "On this phone, a tap opens this thing's page. Change this in ",
                                              ),
                                              TextSpan(
                                                text: 'Edit Profile',
                                                style: TextStyle(
                                                  color: scheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                recognizer: _editProfileTap,
                                              ),
                                              const TextSpan(text: '.'),
                                            ],
                                          ),
                                        )
                                      else
                                        Text(
                                          'Write a tag so a tap logs this '
                                          'thing.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              icon: const Icon(Icons.nfc),
                              label: Text(
                                _hasTag
                                    ? 'Write another NFC tag'
                                    : 'Write an NFC tag',
                              ),
                              onPressed: _busy ? null : _writeTag,
                            ),
                            if (_hasTag)
                              TextButton(
                                onPressed: _busy ? null : _forgetTag,
                                child: const Text('Forget tag'),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoresSection extends ConsumerStatefulWidget {
  final String subjectId;
  const _ChoresSection({required this.subjectId});

  @override
  ConsumerState<_ChoresSection> createState() => _ChoresSectionState();
}

class _ChoresSectionState extends ConsumerState<_ChoresSection> {
  /// True while a chore chip is being long-press dragged - the Add slot
  /// morphs into the red Remove drop target for the duration.
  bool _dragging = false;

  Future<void> _confirmAndDelete(Chore chore) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${chore.name}?'),
        content: const Text(
          'Its schedule and reminders go with it. Past completions stay '
          'in the history.',
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
    try {
      await ref.read(choreActionsProvider).deleteChore(chore.id);
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncChores = ref.watch(choresControllerProvider);
    final chores =
        (asyncChores.valueOrNull ?? const [])
            .where((c) => c.subjectId == widget.subjectId)
            .toList()
          ..sort(
            (a, b) =>
                (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage chores',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final c in chores)
                  _ChoreChip(
                    chore: c,
                    onTap: () => context.push(Routes.choreEdit(c.id)),
                    onDragChanged: (active) =>
                        setState(() => _dragging = active),
                  ),
                if (_dragging)
                  _RemoveChoreChip(onDrop: _confirmAndDelete)
                else
                  _AddChoreChip(
                    onTap: () =>
                        context.push(Routes.choreNew(widget.subjectId)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One chore in the manage-chores cloud: pastel circle with a clock,
/// pencil badge on the edge, name + schedule underneath. Tap to edit;
/// long-press to lift and drag onto the Remove slot to delete.
class _ChoreChip extends StatelessWidget {
  final Chore chore;
  final VoidCallback onTap;

  /// Fired with true when a long-press drag lifts this chip, false when
  /// the drag ends (dropped or cancelled). The parent swaps the Add slot
  /// for the Remove bin while any drag is live.
  final ValueChanged<bool> onDragChanged;

  const _ChoreChip({
    required this.chore,
    required this.onTap,
    required this.onDragChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chip = _chipBody(theme, scheme);
    return LongPressDraggable<Chore>(
      data: chore,
      onDragStarted: () => onDragChanged(true),
      onDragEnd: (_) => onDragChanged(false),
      // The lifted copy swaps its pencil badge for a red cross - you're
      // carrying it toward the bin, not editing it.
      feedback: Material(
        color: Colors.transparent,
        child: _chipBody(theme, scheme, removing: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      ),
    );
  }

  Widget _chipBody(
    ThemeData theme,
    ColorScheme scheme, {
    bool removing = false,
  }) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(
                  chore.isOnce ? Icons.event : Icons.schedule,
                  size: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: removing ? Colors.red : scheme.primary,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    removing ? Icons.close : Icons.edit,
                    size: 11,
                    color: removing ? Colors.white : scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            chore.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            chore.rule.humanLabel(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Drop target the Add slot morphs into while a chore chip is being
/// dragged - dashed red circle with a bin, fills solid on hover. Dropping
/// hands the chore to [onDrop] (which confirms before deleting).
class _RemoveChoreChip extends StatelessWidget {
  final ValueChanged<Chore> onDrop;

  const _RemoveChoreChip({required this.onDrop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<Chore>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        final red = hovering ? Colors.red : Colors.red.shade300;
        return SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                painter: DashedCirclePainter(color: red, filled: hovering),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.delete_outline,
                    size: 24,
                    color: hovering ? Colors.white : red,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Delete',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Trailing "Add chore" affordance - dashed circle with a plus, styled
/// like the chore chips so it reads as the next empty slot.
class _AddChoreChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChoreChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: DashedCirclePainter(color: accent),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.add, size: 24, color: accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
