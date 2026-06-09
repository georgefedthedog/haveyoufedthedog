import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'recent_completions_controller.dart';

part 'streak_controller.g.dart';

/// Number of consecutive days (ending today or yesterday) that this
/// subject has at least one completion logged.
///
/// "Today" counts as a streak day once you log anything; "yesterday"
/// keeps the streak alive while you haven't yet logged today's chores.
/// If the latest completion is older than yesterday, the streak is 0.
///
/// Derived from [recentCompletionsControllerProvider] — no extra fetch.
@riverpod
int subjectStreak(Ref ref, String subjectId) {
  final list = ref
          .watch(recentCompletionsControllerProvider(subjectId))
          .valueOrNull ??
      const [];
  if (list.isEmpty) return 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Deduplicate to days. Recent completions are sorted desc by
  // `completed_at`, so walking the list gives us latest-first days.
  final dayKeys = <DateTime>{};
  for (final c in list) {
    final d = c.completedAt;
    dayKeys.add(DateTime(d.year, d.month, d.day));
  }
  final sortedDays = dayKeys.toList()..sort((a, b) => b.compareTo(a));

  // Anchor: latest day must be today or yesterday, else streak broken.
  final latest = sortedDays.first;
  final gap = today.difference(latest).inDays;
  if (gap > 1) return 0;

  var streak = 1;
  var prev = latest;
  for (final d in sortedDays.skip(1)) {
    final expected = prev.subtract(const Duration(days: 1));
    if (d.year == expected.year &&
        d.month == expected.month &&
        d.day == expected.day) {
      streak += 1;
      prev = d;
    } else {
      break;
    }
  }
  return streak;
}
