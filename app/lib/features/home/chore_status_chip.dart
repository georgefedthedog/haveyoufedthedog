import 'package:flutter/material.dart';

import '../../core/chores/chore.dart';

/// Pill showing one chore's status for today. Green tick when completed,
/// outlined when still outstanding. Tap is wired in Step 8.
class ChoreStatusChip extends StatelessWidget {
  final Chore chore;
  final bool isCompleted;
  final VoidCallback? onTap;

  const ChoreStatusChip({
    super.key,
    required this.chore,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isCompleted ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isCompleted ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: isCompleted
              ? null
              : Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: fg,
            ),
            const SizedBox(width: 6),
            Text(
              chore.name,
              style: TextStyle(color: fg, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
