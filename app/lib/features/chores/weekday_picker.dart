import 'package:flutter/material.dart';

import '../../core/chores/weekdays.dart';

/// Row of 7 toggleable day chips (Mon→Sun). State is a bitmask using
/// [Weekdays.bits] - bit 0 = Mon, bit 6 = Sun, matching
/// `1 << (DateTime.weekday - 1)`.
class WeekdayPicker extends StatelessWidget {
  final int mask;
  final ValueChanged<int> onChanged;

  const WeekdayPicker({super.key, required this.mask, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 7; i++)
          FilterChip(
            label: Text(Weekdays.labels[i]),
            selected: (mask & Weekdays.bits[i]) != 0,
            // No checkmark - it widens the chip on selection and makes
            // the whole row reflow. The fill colour change is enough.
            showCheckmark: false,
            onSelected: (s) => onChanged(
              s ? (mask | Weekdays.bits[i]) : (mask & ~Weekdays.bits[i]),
            ),
          ),
      ],
    );
  }
}
