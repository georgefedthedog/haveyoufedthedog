import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chore_actions.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/chores/schedule_rule.dart';
import '../../core/chores/weekdays.dart';
import '../../widgets/build_label.dart';
import 'weekday_picker.dart';

/// Create or edit a chore for a subject. When [choreId] is non-null we're
/// editing an existing chore; when [subjectId] is non-null we're creating
/// a new one against that subject.
class EditChoreScreen extends ConsumerStatefulWidget {
  /// Null means "create a new chore."
  final String? choreId;

  /// Required when creating; ignored when editing (read off the chore).
  final String? subjectId;

  const EditChoreScreen({
    super.key,
    this.choreId,
    this.subjectId,
  }) : assert(choreId != null || subjectId != null,
            'Need either choreId (edit) or subjectId (create).');

  @override
  ConsumerState<EditChoreScreen> createState() => _EditChoreScreenState();
}

class _EditChoreScreenState extends ConsumerState<EditChoreScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  ScheduleType _scheduleType = ScheduleType.daily;
  int _weekdayMask = Weekdays.all;
  bool _seeded = false;
  bool _busy = false;

  bool get _isEdit => widget.choreId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _seedFromExisting(Chore existing) {
    if (_seeded) return;
    _nameCtrl.text = existing.name;
    _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
    _scheduleType = ScheduleType.fromWire(existing.scheduleType);
    _weekdayMask = existing.weekdayMask;
    _seeded = true;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_scheduleType == ScheduleType.weekly && _weekdayMask == 0) return;

    // For daily chores the mask is irrelevant; force `all` so the server
    // never stores a meaningless mask. (Also satisfies the schema's
    // required+non-zero check, which doubles as a safety net for weekly.)
    final maskToSend =
        _scheduleType == ScheduleType.daily ? Weekdays.all : _weekdayMask;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final actions = ref.read(choreActionsProvider);
      if (_isEdit) {
        await actions.updateChore(
          widget.choreId!,
          name: _nameCtrl.text.trim(),
          scheduleType: _scheduleType,
          hour: _time.hour,
          minute: _time.minute,
          weekdayMask: maskToSend,
        );
      } else {
        await actions.createChore(
          subjectId: widget.subjectId!,
          name: _nameCtrl.text.trim(),
          scheduleType: _scheduleType,
          hour: _time.hour,
          minute: _time.minute,
          weekdayMask: maskToSend,
        );
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
          'All completion history for this chore will be permanently '
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
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(choreActionsProvider).deleteChore(widget.choreId!);
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
    if (_isEdit) {
      final asyncChores = ref.watch(choresControllerProvider);
      final existing = asyncChores.valueOrNull?.firstWhere(
        (c) => c.id == widget.choreId,
        orElse: () => throw StateError('Chore ${widget.choreId} missing'),
      );
      if (existing == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      _seedFromExisting(existing);
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit chore' : 'New chore'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete chore',
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                autofocus: !_isEdit,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Breakfast',
                ),
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Text('Repeats', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ScheduleType>(
                segments: const [
                  ButtonSegment(
                    value: ScheduleType.daily,
                    label: Text('Every day'),
                  ),
                  ButtonSegment(
                    value: ScheduleType.weekly,
                    label: Text('Some days'),
                  ),
                ],
                selected: {_scheduleType},
                onSelectionChanged: (s) =>
                    setState(() => _scheduleType = s.first),
              ),
              if (_scheduleType == ScheduleType.weekly) ...[
                const SizedBox(height: 16),
                Text('On these days',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                WeekdayPicker(
                  mask: _weekdayMask,
                  onChanged: (m) => setState(() => _weekdayMask = m),
                ),
                if (_weekdayMask == 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Pick at least one day.',
                    style: TextStyle(color: scheme.error),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Text('Time', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(_time.format(context)),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickTime,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(_isEdit ? 'Save changes' : 'Add chore'),
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
