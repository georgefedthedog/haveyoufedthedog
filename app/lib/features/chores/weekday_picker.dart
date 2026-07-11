import 'package:flutter/material.dart';

import '../../core/chores/schedule_labels.dart';
import '../../core/chores/weekdays.dart';
import '../../l10n/l10n.dart';
import '../../widgets/single_select_chips.dart';

/// Row of 7 toggleable day chips (Mon→Sun). State is a bitmask using
/// [Weekdays.bits] - bit 0 = Mon, bit 6 = Sun, matching
/// `1 << (DateTime.weekday - 1)`.
class WeekdayPicker extends StatelessWidget {
  final int mask;
  final ValueChanged<int> onChanged;

  const WeekdayPicker({super.key, required this.mask, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 7; i++)
          FilterChip(
            label: Text(weekdayShort(i + 1, locale)),
            selected: (mask & Weekdays.bits[i]) != 0,
            // Our own fixed-size check avatar (see chipCheck) instead of the
            // built-in checkmark, which would widen the chip on selection.
            showCheckmark: false,
            avatar: chipCheck((mask & Weekdays.bits[i]) != 0),
            onSelected: (s) => onChanged(
              s ? (mask | Weekdays.bits[i]) : (mask & ~Weekdays.bits[i]),
            ),
          ),
      ],
    );
  }
}

/// Single-select day pills (Mon→Sun), same look as [WeekdayPicker] but only
/// one day at a time. [selected] is an ISO weekday (Mon=1 .. Sun=7) - used by
/// the monthly "Nth weekday" picker, which always needs exactly one day.
class SingleWeekdayPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const SingleWeekdayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    return SingleSelectChips<int>(
      selected: selected,
      onChanged: onChanged,
      options: [
        for (var i = 0; i < 7; i++)
          (value: i + 1, label: weekdayShort(i + 1, locale)),
      ],
    );
  }
}
