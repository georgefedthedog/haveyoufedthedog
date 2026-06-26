import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chore_actions.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/chores/schedule_rule.dart';
import '../../core/chores/weekdays.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/single_select_chips.dart';
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
  // Default for a new "Some days" chore: just Monday (editing seeds from the
  // stored mask; daily chores ignore this and save `all`).
  int _weekdayMask = Weekdays.mon;
  int _weekInterval = 1;
  // Fortnightly only: whether the "on" weeks start next week vs this week.
  // Resolved to a stored week_phase at save time (_resolveWeekPhase).
  bool _startsNextWeek = false;
  // Monthly.
  MonthMode _monthMode = MonthMode.day;
  int _monthDay = 1; // 1..28, or ScheduleRule.last
  int _monthOrdinal = 1; // 1..4, or ScheduleRule.last
  int _monthWeekday = DateTime.monday; // ISO 1..7
  // One-time: the due date (date-only). Null until the user picks "Once" (we
  // seed it to today on that switch), or seeded from an existing one-off.
  DateTime? _onceDate;
  // Schedule mode: true = a single dated task, false = a recurring frequency.
  // Kept separate from [_scheduleType] (which only ever holds daily/weekly/
  // monthly) so a one-off isn't crammed into the "Repeats" frequency row.
  bool _isOnce = false;
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
    final seedType = ScheduleType.fromWire(existing.scheduleType);
    _isOnce = seedType == ScheduleType.once;
    // The frequency row never holds "once" (the mode toggle owns that), so a
    // one-off's hidden frequency just defaults to daily.
    _scheduleType = _isOnce ? ScheduleType.daily : seedType;
    _weekdayMask = existing.weekdayMask;
    _weekInterval = const {1, 2}.contains(existing.weekInterval)
        ? existing.weekInterval
        : 1;
    // "Next week" = stored phase differs from the current week's parity.
    _startsNextWeek =
        existing.weekInterval > 1 &&
        existing.weekPhase != ScheduleRule.weekPhaseForDate(DateTime.now());
    _monthMode = existing.monthMode;
    _monthDay = existing.monthDay;
    _monthOrdinal = existing.monthOrdinal;
    _monthWeekday = existing.monthWeekday;
    _onceDate = existing.onceDate;
    _seeded = true;
  }

  /// Sentinel for the "Which" chip row meaning the by-date mode (not an
  /// ordinal). Picked so it can't collide with a real ordinal (1..4 or -1).
  static const int _exactDay = 0;

  /// Maps a "Which" chip selection onto the monthly mode: "Exact Day" switches
  /// to by-date; any ordinal switches to by-weekday and stores the ordinal.
  void _onMonthWhichChanged(int value) {
    setState(() {
      if (value == _exactDay) {
        _monthMode = MonthMode.day;
      } else {
        _monthMode = MonthMode.weekday;
        _monthOrdinal = value;
      }
    });
  }

  /// Resolves the fortnightly this/next-week choice into a stored phase.
  int _resolveWeekPhase() {
    final base = ScheduleRule.weekPhaseForDate(DateTime.now());
    return _startsNextWeek ? (base + 1) % 2 : base;
  }

  /// The chore's rule from the current form state, shared by the live preview
  /// and the save path so the two can't drift.
  ScheduleRule _buildRule() {
    if (_isOnce) {
      return ScheduleRule.once(
        hour: _time.hour,
        minute: _time.minute,
        onceDate: _onceDate ?? _today(),
      );
    }
    switch (_scheduleType) {
      case ScheduleType.daily:
        return ScheduleRule.daily(hour: _time.hour, minute: _time.minute);
      case ScheduleType.weekly:
        return ScheduleRule.weekly(
          hour: _time.hour,
          minute: _time.minute,
          weekdayMask: _weekdayMask,
          weekInterval: _weekInterval,
          weekPhase: _weekInterval > 1 ? _resolveWeekPhase() : 0,
        );
      case ScheduleType.monthly:
        return ScheduleRule(
          type: ScheduleType.monthly,
          hour: _time.hour,
          minute: _time.minute,
          monthMode: _monthMode,
          monthDay: _monthDay,
          monthOrdinal: _monthOrdinal,
          monthWeekday: _monthWeekday,
        );
      case ScheduleType.once:
        // Unreachable - the mode toggle handles one-offs above - but the switch
        // must stay exhaustive.
        return ScheduleRule.once(
          hour: _time.hour,
          minute: _time.minute,
          onceDate: _onceDate ?? _today(),
        );
    }
  }

  /// Today, date-only - the fallback one-off date before the user has picked.
  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Static preview of the chore in its neutral state - always shows the
  /// full name and the complete schedule line (days + time), regardless
  /// of whether the chore would currently be overdue / due-soon. The
  /// styling mirrors ChoreRow's resting look without its live status.
  Widget _buildPreviewRow() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = _nameCtrl.text.trim();
    final rule = _buildRule();
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
              child: Icon(_isOnce ? Icons.event : Icons.schedule, size: 22),
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

  // Monthly dropdown options: days 1-28 plus "Last day"; the by-weekday
  // ordinal (First..Fourth, Last); and the weekday (Mon..Sun, ISO 1-7).
  List<DropdownMenuItem<int>> get _monthDayItems => [
    for (var d = 1; d <= 28; d++)
      DropdownMenuItem(value: d, child: Text('The ${ScheduleRule.ordinal(d)}')),
    const DropdownMenuItem(
      value: ScheduleRule.last,
      child: Text('The last day'),
    ),
  ];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final today = _today();
    // Clamp the initial date up to today - a carried-over (past) one-off can't
    // re-seed the picker below firstDate, but its stored date stays on the
    // tile until the user actually picks a new one.
    final seed = _onceDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: seed.isBefore(today) ? today : seed,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) setState(() => _onceDate = picked);
  }

  /// "Wed, 30 Jun 2027" for the one-off date tile.
  String _onceDateLabel() {
    final d = _onceDate;
    if (d == null) return 'Pick a date';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${Weekdays.labels[d.weekday - 1]}, '
        '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_isOnce && _scheduleType == ScheduleType.weekly && _weekdayMask == 0) {
      return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final actions = ref.read(choreActionsProvider);
      final rule = _buildRule();
      if (_isEdit) {
        await actions.updateChore(
          widget.choreId!,
          name: _nameCtrl.text.trim(),
          rule: rule,
        );
      } else {
        await actions.createChore(
          subjectId: widget.subjectId!,
          name: _nameCtrl.text.trim(),
          rule: rule,
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
                      // Recurring vs a single dated task. Separate from the
                      // frequency below because a one-off isn't a "repeat".
                      LabeledField(
                        label: 'Schedule',
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: false, label: Text('Repeats')),
                            ButtonSegment(value: true, label: Text('One time')),
                          ],
                          selected: {_isOnce},
                          onSelectionChanged: (s) => setState(() {
                            _isOnce = s.first;
                            // Seed today the first time "One time" is chosen so
                            // the date tile shows a real date straight away.
                            if (_isOnce && _onceDate == null) {
                              _onceDate = _today();
                            }
                          }),
                        ),
                      ),
                      if (!_isOnce) ...[
                        const SizedBox(height: 24),
                        LabeledField(
                          label: 'Frequency',
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
                              ButtonSegment(
                                value: ScheduleType.monthly,
                                label: Text('Monthly'),
                              ),
                            ],
                            selected: {_scheduleType},
                            onSelectionChanged: (s) =>
                                setState(() => _scheduleType = s.first),
                          ),
                        ),
                      ],
                      if (!_isOnce && _scheduleType == ScheduleType.weekly) ...[
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
                            ],
                            selected: {_weekInterval},
                            onSelectionChanged: (s) =>
                                setState(() => _weekInterval = s.first),
                          ),
                        ),
                        if (_weekInterval > 1) ...[
                          const SizedBox(height: 16),
                          LabeledField(
                            label: 'Starting',
                            child: SingleSelectChips<bool>(
                              selected: _startsNextWeek,
                              onChanged: (v) =>
                                  setState(() => _startsNextWeek = v),
                              options: const [
                                (value: false, label: 'This week'),
                                (value: true, label: 'Next week'),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (!_isOnce &&
                          _scheduleType == ScheduleType.monthly) ...[
                        const SizedBox(height: 16),
                        // "Exact Day" leads the row and selects by date; the
                        // ordinals select the Nth (or last) weekday. The chip
                        // choice drives _monthMode (see _onMonthWhichChanged).
                        LabeledField(
                          label: 'On the',
                          child: SingleSelectChips<int>(
                            selected: _monthMode == MonthMode.day
                                ? _exactDay
                                : _monthOrdinal,
                            onChanged: _onMonthWhichChanged,
                            options: const [
                              (value: _exactDay, label: 'Exact Day'),
                              (value: 1, label: 'First'),
                              (value: 2, label: 'Second'),
                              (value: 3, label: 'Third'),
                              (value: 4, label: 'Fourth'),
                              (value: ScheduleRule.last, label: 'Last'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_monthMode == MonthMode.day)
                          LabeledField(
                            label: 'Day',
                            child: DropdownButtonFormField<int>(
                              initialValue: _monthDay,
                              items: _monthDayItems,
                              onChanged: (v) =>
                                  setState(() => _monthDay = v ?? _monthDay),
                            ),
                          )
                        else
                          LabeledField(
                            label: 'Weekday',
                            child: SingleWeekdayPicker(
                              selected: _monthWeekday,
                              onChanged: (w) =>
                                  setState(() => _monthWeekday = w),
                            ),
                          ),
                      ],
                      if (_isOnce) ...[
                        const SizedBox(height: 24),
                        LabeledField(
                          label: 'On',
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: scheme.surfaceContainerHigh,
                            child: ListTile(
                              leading: const Icon(Icons.event),
                              title: Text(_onceDateLabel()),
                              trailing: const Icon(Icons.edit),
                              onTap: _pickDate,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      LabeledField(
                        label: 'At',
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
