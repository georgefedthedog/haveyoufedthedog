import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/subject.dart';
import 'chore_status_chip.dart';

/// One row in the subjects list on the home screen. Shows the subject and
/// a chip per chore that's due today. Step 8 wires chip taps to log a
/// completion.
class SubjectCard extends ConsumerWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.subject, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChores = ref.watch(choresControllerProvider);
    final asyncCompletions = ref.watch(todayCompletionsControllerProvider);

    final today = DateTime.now();
    final chores = asyncChores.valueOrNull ?? const <Chore>[];
    final dueToday = chores
        .where((c) => c.subjectId == subject.id && c.rule.isDueOn(today))
        .toList();

    final completions = asyncCompletions.valueOrNull;
    final completedChoreIds = completions == null
        ? const <String>{}
        : {
            for (final c in completions)
              if (c.choreId != null) c.choreId!,
          };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: _Avatar(icon: subject.icon),
              title: Text(subject.name),
              subtitle: subject.nfcTagId != null
                  ? const Text('NFC tag registered')
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: onTap,
            ),
            if (dueToday.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in dueToday)
                      ChoreStatusChip(
                        chore: c,
                        isCompleted: completedChoreIds.contains(c.id),
                        // TODO(step-8): log a completion on tap.
                        onTap: null,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? icon;
  const _Avatar({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child: Text(
        (icon != null && icon!.isNotEmpty) ? icon! : '🐾',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
