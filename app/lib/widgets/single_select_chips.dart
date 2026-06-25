import 'package:flutter/material.dart';

/// Fixed-size leading slot for a chip: a check when [selected], an equally
/// sized empty box otherwise. Reserving the space in both states keeps chips
/// (and their row) from reflowing when selection toggles.
Widget chipCheck(bool selected) => selected
    ? const Icon(Icons.check, size: 18)
    : const SizedBox(width: 18, height: 18);

/// One value out of [options], rendered as a wrap of single-select pills with
/// the fixed-size [chipCheck] leading slot. Used for the monthly weekday and
/// "which occurrence" pickers.
class SingleSelectChips<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const SingleSelectChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o.label),
            selected: o.value == selected,
            showCheckmark: false,
            avatar: chipCheck(o.value == selected),
            // Re-tapping the current value keeps it; there's no empty state.
            onSelected: (_) => onChanged(o.value),
          ),
      ],
    );
  }
}
