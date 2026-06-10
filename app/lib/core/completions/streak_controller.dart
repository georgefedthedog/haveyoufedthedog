import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../chores/chore.dart';
import '../chores/chores_controller.dart';
import 'recent_completions_controller.dart';

part 'streak_controller.g.dart';

/// Number of consecutive **due days** that this subject has at least one
/// completion logged for.
///
/// Walks back from today asking, for each calendar day: *is any active
/// chore for this subject scheduled on this day?*
///   - **No** → skip the day, don't count, don't break. A weekly Tuesday
///     chore doesn't reset its own streak on Wednesday.
///   - **Yes, satisfied** (any completion that day) → +1 to streak.
///   - **Yes, unsatisfied** → streak breaks. **Exception**: today gets a
///     grace pass — an outstanding chore due today doesn't break the
///     streak you carried in from earlier days.
///
/// We bound the walk to the earliest completion in the recent list so we
/// don't loop into infinite empty history. Without a chore or without
/// any completion at all, the streak is 0.
///
/// Derived from [recentCompletionsControllerProvider] and
/// [choresControllerProvider] — no extra fetch.
@riverpod
int subjectStreak(Ref ref, String subjectId) {
  final completions = ref
          .watch(recentCompletionsControllerProvider(subjectId))
          .valueOrNull ??
      const [];
  final allChores = ref.watch(choresControllerProvider).valueOrNull ??
      const <Chore>[];

  final subjectChores = [
    for (final c in allChores)
      if (c.subjectId == subjectId && c.active) c,
  ];
  if (subjectChores.isEmpty || completions.isEmpty) return 0;

  // Dedupe completions to local-day keys for cheap membership checks.
  final completedDays = <DateTime>{};
  DateTime? earliestCompletion;
  for (final c in completions) {
    final d = c.completedAt;
    final day = DateTime(d.year, d.month, d.day);
    completedDays.add(day);
    if (earliestCompletion == null || day.isBefore(earliestCompletion)) {
      earliestCompletion = day;
    }
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var streak = 0;
  // Hard cap: walk at most a year — anything older isn't in our recent
  // completions window anyway. We break out via `earliestCompletion`
  // first in practice.
  for (var offset = 0; offset <= 366; offset++) {
    final day = today.subtract(Duration(days: offset));
    if (day.isBefore(earliestCompletion!)) break;

    final isDueDay = subjectChores.any((c) => c.rule.isDueOn(day));
    if (!isDueDay) continue;

    if (completedDays.contains(day)) {
      streak += 1;
    } else if (offset == 0) {
      // Grace: today's unsatisfied chore doesn't break a carried streak.
      continue;
    } else {
      break;
    }
  }
  return streak;
}
