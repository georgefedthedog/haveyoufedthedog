import 'package:flutter/material.dart';

import '../../core/chores/chore.dart';
import '../../core/completions/completion.dart';

/// Pill showing one chore's status for today. Outlined when outstanding
/// (shows scheduled time); filled green-tick when completed (shows the
/// actual time logged). Tap behaviour comes from [onTap].
class ChoreStatusChip extends StatelessWidget {
  final Chore chore;
  final Completion? completion;
  final VoidCallback? onTap;

  const ChoreStatusChip({
    super.key,
    required this.chore,
    this.completion,
    this.onTap,
  });

  bool get _isCompleted => completion != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _isCompleted
        ? Colors.green.shade100
        : scheme.surfaceContainerHighest;
    final fg = _isCompleted
        ? Colors.green.shade900
        : scheme.onSurfaceVariant;

    final time = _isCompleted
        ? TimeOfDay.fromDateTime(completion!.completedAt).format(context)
        : chore.rule.timeOfDay.format(context);
    final label = '${chore.name} · $time';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: _isCompleted
              ? null
              : Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isCompleted ? Icons.check_circle : Icons.schedule,
              size: 16,
              color: fg,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
