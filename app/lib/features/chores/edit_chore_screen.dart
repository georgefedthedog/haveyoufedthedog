import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chore_actions.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/chores/schedule_rule.dart';
import '../../core/chores/weekdays.dart';
import '../../widgets/labeled_field.dart';
import 'weekday_picker.dart';

/// Create or edit a chore for a subject. When [choreId] is non-null we're
/// editing an existing chore; when [subjectId] is non-null we're creating
/// a new one against that subject.
class EditChoreScreen extends ConsumerStatefulWidget {
  /// Null means "create a new chore."
  final String? choreId;

  /// Required when creating; ignored when editing (read off the chore).
  final String? subjectId;

  const EditChoreScreen({super.key, this.choreId, this.subjectId})
    : assert(
        choreId != null || subjectId != null,
        'Need either choreId (edit) or subjectId (create).',
      );

  @override
  ConsumerState<EditChoreScreen> createState() => _EditChoreScreenState();
}

class _EditChoreScreenState extends ConsumerState<EditChoreScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  ScheduleType _scheduleType = ScheduleType.daily;
  int _weekdayMask = Weekdays.all;
  int _weekInterval = 1;
  // The user's chosen anchor; the stored/previewed start is this snapped
  // forward to the next day that's actually in the mask (_snappedStartDate).
  DateTime _startDate = DateTime.now();
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
    _weekInterval = const {1, 2, 4}.contains(existing.weekInterval)
        ? existing.weekInterval
        : 1;
    final es = existing.startDate;
    if (es != null) _startDate = DateTime(es.year, es.month, es.day);
    _seeded = true;
  }

  /// The chosen anchor snapped forward to the next day whose weekday is in
  /// the mask - so the stored start is always a real occurrence. Returns the
  /// raw anchor unchanged when the mask is empty (save is guarded anyway).
  DateTime _snappedStartDate() {
    var d = DateTime(_startDate.year, _startDate.month, _startDate.day);
    for (var i = 0; i < 7; i++) {
      if ((_weekdayMask & Weekdays.bitFor(d)) != 0) return d;
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  /// Static preview of the chore in its neutral state - always shows the
  /// full name and the complete schedule line (days + time), regardless
  /// of whether the chore would currently be overdue / due-soon. The
  /// styling mirrors ChoreRow's resting look without its live status.
  Widget _buildPreviewRow() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = _nameCtrl.text.trim();
    final weekly = _scheduleType == ScheduleType.weekly;
    final rule = ScheduleRule(
      type: _scheduleType,
      hour: _time.hour,
      minute: _time.minute,
      weekdayMask: weekly ? _weekdayMask : Weekdays.all,
      weekInterval: weekly ? _weekInterval : 1,
      startDate: weekly && _weekInterval > 1 ? _snappedStartDate() : null,
    );
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundColor: scheme.onSurfaceVariant,
              child: const Icon(Icons.schedule, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'New chore' : name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rule.humanLabel(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _snappedStartDate(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_scheduleType == ScheduleType.weekly && _weekdayMask == 0) return;

    // For daily chores the mask is irrelevant; force `all` so the server
    // never stores a meaningless mask. (Also satisfies the schema's
    // required+non-zero check, which doubles as a safety net for weekly.)
    final weekly = _scheduleType == ScheduleType.weekly;
    final maskToSend = weekly ? _weekdayMask : Weekdays.all;
    final intervalToSend = weekly ? _weekInterval : 1;
    final startToSend = weekly && _weekInterval > 1 ? _snappedStartDate() : null;

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
          weekInterval: intervalToSend,
          startDate: startToSend,
        );
      } else {
        await actions.createChore(
          subjectId: widget.subjectId!,
          name: _nameCtrl.text.trim(),
          scheduleType: _scheduleType,
          hour: _time.hour,
          minute: _time.minute,
          weekdayMask: maskToSend,
          weekInterval: intervalToSend,
          startDate: startToSend,
        );
      }
      if (mounted) router.pop();
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
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not delete: $e')),
      );
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
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
              // Live preview of the chore's name + full schedule line,
              // updating as the form changes.
              _buildPreviewRow(),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: 'Name',
                        child: TextFormField(
                          controller: _nameCtrl,
                          autofocus: !_isEdit,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Breakfast',
                          ),
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LabeledField(
                        label: 'Repeats',
                        child: SegmentedButton<ScheduleType>(
                          showSelectedIcon: false,
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
                      ),
                      if (_scheduleType == ScheduleType.weekly) ...[
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'On these days',
                          child: WeekdayPicker(
                            mask: _weekdayMask,
                            onChanged: (m) => setState(() => _weekdayMask = m),
                          ),
                        ),
                        if (_weekdayMask == 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Pick at least one day.',
                            style: TextStyle(color: scheme.error),
                          ),
                        ],
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'How often',
                          child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: 1,
                                label: Text('Every week'),
                              ),
                              ButtonSegment(
                                value: 2,
                                label: Text('Fortnightly'),
                              ),
                              ButtonSegment(value: 4, label: Text('4 weeks')),
                            ],
                            selected: {_weekInterval},
                            onSelectionChanged: (s) =>
                                setState(() => _weekInterval = s.first),
                          ),
                        ),
                        if (_weekInterval > 1) ...[
                          const SizedBox(height: 16),
                          LabeledField(
                            label: 'Starts',
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: scheme.surfaceContainerHigh,
                              child: ListTile(
                                leading: const Icon(Icons.event),
                                title: Text(
                                  _weekdayMask == 0
                                      ? 'Pick a day first'
                                      : MaterialLocalizations.of(
                                          context,
                                        ).formatMediumDate(_snappedStartDate()),
                                ),
                                trailing: const Icon(Icons.edit),
                                onTap: _weekdayMask == 0 ? null : _pickStartDate,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                      LabeledField(
                        label: 'Time',
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerHigh,
                          child: ListTile(
                            leading: const Icon(Icons.schedule),
                            title: Text(
                              ScheduleRule.formatClock(
                                _time.hour,
                                _time.minute,
                              ),
                            ),
                            trailing: const Icon(Icons.edit),
                            onTap: _pickTime,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(_isEdit ? 'Save changes' : 'Add chore'),
                        onPressed: _busy ? null : _save,
                      ),
                    ],
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
