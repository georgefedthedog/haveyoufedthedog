import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chore_actions.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/chores/schedule_labels.dart';
import '../../core/chores/schedule_rule.dart';
import '../../core/chores/weekdays.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../l10n/l10n.dart';
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
  Widget _buildPreviewRow(Subject? subject) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = _nameCtrl.text.trim();
    final rule = _buildRule();
    // The subject's character on the left (generic fallback if it isn't
    // resolved yet); the schedule-type icon on the right - a clock for
    // recurring, a calendar for a one-off (matching the list rows).
    final character = ref.watch(catalogProvider).lookupCharacter(subject?.icon);
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
            SizedBox(
              width: 44,
              height: 44,
              child: ClipOval(
                child: ColoredBox(
                  color: character.stageColor,
                  child: CharacterArtwork(
                    character: character,
                    expression: CharacterExpression.idle,
                    stage: false,
                    iconSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? context.l10n.editChoreNewTitle : name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    describeSchedule(rule, context.l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              _isOnce ? Icons.event : Icons.schedule,
              color: scheme.onSurfaceVariant,
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
      DropdownMenuItem(
        value: d,
        child: Text(
          context.l10n.editChoreMonthDayItem(
            ordinalDay(d, context.l10n.localeName),
          ),
        ),
      ),
    DropdownMenuItem(
      value: ScheduleRule.last,
      child: Text(context.l10n.editChoreLastDay),
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
    if (d == null) return context.l10n.editChorePickDate;
    return fullDate(d, context.l10n.localeName);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_isOnce && _scheduleType == ScheduleType.weekly && _weekdayMask == 0) {
      return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l10n = context.l10n;
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
        SnackBar(
          showCloseIcon: true,
          content: Text(l10n.commonCouldNotSave('$e')),
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.commonDeleteTitle(_nameCtrl.text)),
        content: Text(ctx.l10n.editChoreDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(choreActionsProvider).deleteChore(widget.choreId!);
      if (mounted) router.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(l10n.commonCouldNotDelete('$e')),
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Chore? existing;
    if (_isEdit) {
      final asyncChores = ref.watch(choresControllerProvider);
      existing = asyncChores.valueOrNull?.firstWhere(
        (c) => c.id == widget.choreId,
        orElse: () => throw StateError('Chore ${widget.choreId} missing'),
      );
      if (existing == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _seedFromExisting(existing);
    }

    final scheme = Theme.of(context).colorScheme;

    // The subject behind this chore - the create-time arg, or the edited
    // chore's subject - resolved for the preview's portrait.
    final subjectId = widget.subjectId ?? existing?.subjectId;
    final subjects =
        ref.watch(subjectsControllerProvider).valueOrNull ?? const <Subject>[];
    Subject? subject;
    for (final s in subjects) {
      if (s.id == subjectId) {
        subject = s;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? context.l10n.editChoreTitle
              : context.l10n.editChoreNewTitle,
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.editChoreDeleteTooltip,
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
              _buildPreviewRow(subject),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: context.l10n.editChoreNameLabel,
                        child: TextFormField(
                          controller: _nameCtrl,
                          autofocus: !_isEdit,
                          decoration: InputDecoration(
                            hintText: context.l10n.editChoreNameHint,
                          ),
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? context.l10n.commonRequired
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Recurring vs a single dated task. Separate from the
                      // frequency below because a one-off isn't a "repeat".
                      LabeledField(
                        label: context.l10n.editChoreScheduleLabel,
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(context.l10n.editChoreRepeats),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(context.l10n.editChoreOneTime),
                            ),
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
                          label: context.l10n.editChoreFrequencyLabel,
                          child: SegmentedButton<ScheduleType>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: ScheduleType.daily,
                                label: Text(context.l10n.editChoreFreqDaily),
                              ),
                              ButtonSegment(
                                value: ScheduleType.weekly,
                                label: Text(context.l10n.editChoreFreqWeekly),
                              ),
                              ButtonSegment(
                                value: ScheduleType.monthly,
                                label: Text(context.l10n.editChoreFreqMonthly),
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
                          label: context.l10n.editChoreOnTheseDays,
                          child: WeekdayPicker(
                            mask: _weekdayMask,
                            onChanged: (m) => setState(() => _weekdayMask = m),
                          ),
                        ),
                        if (_weekdayMask == 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.editChorePickOneDay,
                            style: TextStyle(color: scheme.error),
                          ),
                        ],
                        const SizedBox(height: 16),
                        LabeledField(
                          label: context.l10n.editChoreHowOften,
                          child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: 1,
                                label: Text(context.l10n.editChoreEveryWeek),
                              ),
                              ButtonSegment(
                                value: 2,
                                label: Text(context.l10n.editChoreFortnightly),
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
                            label: context.l10n.editChoreStarting,
                            child: SingleSelectChips<bool>(
                              selected: _startsNextWeek,
                              onChanged: (v) =>
                                  setState(() => _startsNextWeek = v),
                              options: [
                                (
                                  value: false,
                                  label: context.l10n.editChoreThisWeek,
                                ),
                                (
                                  value: true,
                                  label: context.l10n.editChoreNextWeek,
                                ),
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
                          label: context.l10n.editChoreOnThe,
                          child: SingleSelectChips<int>(
                            selected: _monthMode == MonthMode.day
                                ? _exactDay
                                : _monthOrdinal,
                            onChanged: _onMonthWhichChanged,
                            options: [
                              (
                                value: _exactDay,
                                label: context.l10n.editChoreExactDay,
                              ),
                              (value: 1, label: context.l10n.editChorePosFirst),
                              (
                                value: 2,
                                label: context.l10n.editChorePosSecond,
                              ),
                              (value: 3, label: context.l10n.editChorePosThird),
                              (
                                value: 4,
                                label: context.l10n.editChorePosFourth,
                              ),
                              (
                                value: ScheduleRule.last,
                                label: context.l10n.editChorePosLast,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_monthMode == MonthMode.day)
                          LabeledField(
                            label: context.l10n.editChoreDayLabel,
                            child: DropdownButtonFormField<int>(
                              initialValue: _monthDay,
                              items: _monthDayItems,
                              onChanged: (v) =>
                                  setState(() => _monthDay = v ?? _monthDay),
                            ),
                          )
                        else
                          LabeledField(
                            label: context.l10n.editChoreWeekdayLabel,
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
                          label: context.l10n.editChoreOnDateLabel,
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
                        label: context.l10n.editChoreAtTimeLabel,
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerHigh,
                          child: ListTile(
                            leading: const Icon(Icons.schedule),
                            title: Text(
                              formatClock(
                                _time.hour,
                                _time.minute,
                                context.l10n.localeName,
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
                        label: Text(
                          _isEdit
                              ? context.l10n.commonSaveChanges
                              : context.l10n.editChoreAddChore,
                        ),
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
